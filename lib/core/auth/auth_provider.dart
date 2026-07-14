// lib/core/auth/auth_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jireta_loan/core/auth/token_storage.dart';
import 'package:jireta_loan/core/utils/constants.dart';

sealed class AppAuthState {
  const AppAuthState();
}

class AppAuthLoading extends AppAuthState {
  const AppAuthLoading();
}

class AppAuthUnauthenticated extends AppAuthState {
  const AppAuthUnauthenticated();
}

class AppAuthAuthenticated extends AppAuthState {
  final String userId;
  final String email;
  final String role;
  final String? fullName;
  final String? avatarUrl;

  const AppAuthAuthenticated({
    required this.userId,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
  });

  bool get isHeadManager => role == AppConstants.roleHeadManager;
  bool get isEmployee => role == AppConstants.roleEmployee;
  bool get isRider => role == AppConstants.roleRider;
  bool get isLender => role == AppConstants.roleLender;

  @override
  String toString() => 'AppAuthAuthenticated(userId: $userId, email: $email, role: $role)';
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  final SupabaseClient _supabase;
  final TokenStorage _tokenStorage;
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifier({
    required SupabaseClient supabase,
    required TokenStorage tokenStorage,
  })  : _supabase = supabase,
        _tokenStorage = tokenStorage,
        super(const AppAuthLoading()) {
    _init();
  }

  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _persistSession(session);
      state = _mapSession(session);
    } else {
      state = const AppAuthUnauthenticated();
    }

    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null) {
        _persistSession(session);
        state = _mapSession(session);
      } else {
        _tokenStorage.clearAll();
        state = const AppAuthUnauthenticated();
      }
    });
  }

  AppAuthState _mapSession(Session session) {
    final user = session.user;
    final role = _extractRole(user);
    return AppAuthAuthenticated(
      userId: user.id,
      email: user.email ?? '',
      role: role,
      fullName: user.userMetadata?['full_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  String _extractRole(User user) {
    final appRole = user.appMetadata['role'] as String?;
    if (appRole != null && AppConstants.validRoles.contains(appRole)) {
      return appRole;
    }
    return AppConstants.roleLender;
  }

  Future<void> _persistSession(Session session) async {
    await _tokenStorage.saveAuthData(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      userId: session.user.id,
      userRole: _extractRole(session.user),
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = AppConstants.roleLender,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

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

  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _tokenStorage.clearAll();
  }

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

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError(
    'tokenStorageProvider must be overridden in platform main.dart',
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final supabase = Supabase.instance.client;
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(
    supabase: supabase,
    tokenStorage: tokenStorage,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AppAuthAuthenticated;
});

final currentUserRoleProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AppAuthAuthenticated) {
    return state.role;
  }
  return null;
});

final currentUserProvider = Provider<AppAuthAuthenticated?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AppAuthAuthenticated) {
    return state;
  }
  return null;
});
