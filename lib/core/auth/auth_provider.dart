import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lendflow/core/auth/token_storage.dart';
import 'package:lendflow/core/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────
// Auth state model
// ─────────────────────────────────────────────────────────────────

/// Represents the current authentication state of the app.
sealed class AuthState {
  const AuthState();
}

/// Initial / indeterminate state while checking stored credentials.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No authenticated session.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Authenticated session with role information.
class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;
  final String role;
  final String? fullName;
  final String? avatarUrl;

  const AuthAuthenticated({
    required this.userId,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
  });

  /// Convenience getters for role-based checks.
  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isManager => role == AppConstants.roleManager;
  bool get isRider => role == AppConstants.roleRider;
  bool get isBorrower => role == AppConstants.roleBorrower;

  @override
  String toString() => 'AuthAuthenticated(userId: $userId, email: $email, role: $role)';
}

// ─────────────────────────────────────────────────────────────────
// Auth notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [Notifier] that manages auth state via Supabase.
///
/// Listens to Supabase's [authStateChanges] stream and maps
/// events to [AuthState] values. Also persists tokens via
/// [TokenStorage] for the Dio [AuthInterceptor].
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;
  final TokenStorage _tokenStorage;
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifier({
    required SupabaseClient supabase,
    required TokenStorage tokenStorage,
  })  : _supabase = supabase,
        _tokenStorage = tokenStorage,
        super(const AuthLoading()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Check for an existing session.
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _persistSession(session);
      state = _mapSession(session);
    } else {
      state = const AuthUnauthenticated();
    }

    // 2. Listen for subsequent auth events.
    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null) {
        _persistSession(session);
        state = _mapSession(session);
      } else {
        _tokenStorage.clearAll();
        state = const AuthUnauthenticated();
      }
    });
  }

  /// Map a Supabase [Session] to an [AuthAuthenticated] state.
  AuthState _mapSession(Session session) {
    final user = session.user;
    final role = _extractRole(user);
    return AuthAuthenticated(
      userId: user.id,
      email: user.email ?? '',
      role: role,
      fullName: user.userMetadata?['full_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  /// Extract the user's role from JWT claims or user metadata.
  ///
  /// Supabase stores custom claims in `app_metadata.role` or
  /// `user_metadata.role`. We check both, defaulting to borrower.
  String _extractRole(User user) {
    // 1. Check app_metadata (set by admin / database trigger)
    final appRole = user.appMetadata['role'] as String?;
    if (appRole != null && AppConstants.validRoles.contains(appRole)) {
      return appRole;
    }

    // 2. Check user_metadata (set during signup)
    final userRole = user.userMetadata?['role'] as String?;
    if (userRole != null && AppConstants.validRoles.contains(userRole)) {
      return userRole;
    }

    // 3. Default to borrower for safety
    return AppConstants.roleBorrower;
  }

  /// Persist tokens to secure storage for the HTTP layer.
  Future<void> _persistSession(Session session) async {
    await _tokenStorage.saveAuthData(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.user.id,
      userRole: _extractRole(session.user),
    );
  }

  // ── Public actions ─────────────────────────────────────────────

  /// Sign in with email + password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email + password + role.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = AppConstants.roleBorrower,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
  }

  /// Verify an OTP code.
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.signup,
    );
  }

  /// Send a password reset email.
  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Sign out and clear all local data.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _tokenStorage.clearAll();
  }

  /// Refresh the current access token.
  Future<String?> refreshAccessToken() async {
    final response = await _supabase.auth.refreshSession();
    final session = response.session;
    if (session != null) {
      await _persistSession(session);
      return session.accessToken;
    }
    return null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [TokenStorage] implementation based on platform.
///
/// Override this provider in main_web.dart / main_mobile.dart with
/// the platform-appropriate implementation.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError(
    'tokenStorageProvider must be overridden in platform main.dart',
  );
});

/// Provides the [AuthNotifier] and exposes [AuthState].
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabase = Supabase.instance.client;
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(
    supabase: supabase,
    tokenStorage: tokenStorage,
  );
});

/// Convenience provider that yields `true` when authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});

/// Convenience provider that extracts the current user's role.
///
/// Returns `null` when not authenticated.
final currentUserRoleProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) {
    return state.role;
  }
  return null;
});

/// Convenience provider that extracts the current authenticated user.
///
/// Returns `null` when not authenticated.
final currentUserProvider = Provider<AuthAuthenticated?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) {
    return state;
  }
  return null;
});
