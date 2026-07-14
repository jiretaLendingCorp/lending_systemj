import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lendflow/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:lendflow/features/auth/domain/usecases/login_usecase.dart';
import 'package:lendflow/features/auth/domain/usecases/logout_usecase.dart';
import 'package:lendflow/features/auth/domain/usecases/otp_verify_usecase.dart';
import 'package:lendflow/features/auth/domain/usecases/signup_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

// ─────────────────────────────────────────────────────────────────
// Auth state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level auth state managed by [AuthNotifier].
///
/// This is distinct from the core [AuthState] in `core/auth/auth_provider.dart`
/// which handles the global Supabase auth state. This notifier manages
/// the UI-specific state for the auth feature screens (login, signup, etc.).
sealed class AuthFeatureState {
  const AuthFeatureState();
}

/// Initial state, no auth operation in progress.
class AuthInitial extends AuthFeatureState {
  const AuthInitial();
}

/// An auth operation is in progress.
class AuthLoading extends AuthFeatureState {
  const AuthLoading();
}

/// Auth operation succeeded with the resulting [user].
class AuthAuthenticated extends AuthFeatureState {
  final User user;
  const AuthAuthenticated(this.user);
}

/// OTP has been sent; waiting for user to enter the code.
class AuthOtpSent extends AuthFeatureState {
  final String email;
  const AuthOtpSent(this.email);
}

/// Password reset email has been sent.
class AuthPasswordResetSent extends AuthFeatureState {
  const AuthPasswordResetSent();
}

/// An auth operation failed.
class AuthError extends AuthFeatureState {
  final String message;
  final Failure? failure;
  const AuthError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [AuthRemoteDataSource].
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    supabaseClient: Supabase.instance.client,
    dio: ref.watch(dioProvider),
  );
});

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

/// Provides the [LoginUseCase].
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Provides the [SignupUseCase].
final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  return SignupUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Provides the [OtpVerifyUseCase].
final otpVerifyUseCaseProvider = Provider<OtpVerifyUseCase>((ref) {
  return OtpVerifyUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Provides the [LogoutUseCase].
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Provides the [AuthFeatureNotifier] for auth feature screens.
final authFeatureProvider =
    StateNotifierProvider<AuthFeatureNotifier, AuthFeatureState>((ref) {
  return AuthFeatureNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    signupUseCase: ref.watch(signupUseCaseProvider),
    otpVerifyUseCase: ref.watch(otpVerifyUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    repository: ref.watch(authRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// Auth feature notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing auth feature UI state.
///
/// Coordinates the login, signup, OTP, and logout use cases,
/// translating their results into [AuthFeatureState] values
/// that the presentation layer can react to.
class AuthFeatureNotifier extends StateNotifier<AuthFeatureState> {
  final LoginUseCase _loginUseCase;
  final SignupUseCase _signupUseCase;
  final OtpVerifyUseCase _otpVerifyUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepository _repository;

  AuthFeatureNotifier({
    required LoginUseCase loginUseCase,
    required SignupUseCase signupUseCase,
    required OtpVerifyUseCase otpVerifyUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository repository,
  })  : _loginUseCase = loginUseCase,
        _signupUseCase = signupUseCase,
        _otpVerifyUseCase = otpVerifyUseCase,
        _logoutUseCase = logoutUseCase,
        _repository = repository,
        super(const AuthInitial());

  /// Sign in with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (user) => AuthAuthenticated(user),
    );
  }

  /// Register a new account.
  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    state = const AuthLoading();
    final result = await _signupUseCase(
      SignupParams(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      ),
    );
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (user) => AuthOtpSent(email),
    );
  }

  /// Send an OTP to the given email.
  Future<void> sendOtp({required String email}) async {
    state = const AuthLoading();
    final result = await _repository.otpSend(email: email);
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (_) => AuthOtpSent(email),
    );
  }

  /// Verify the OTP code.
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = const AuthLoading();
    final result = await _otpVerifyUseCase(
      OtpVerifyParams(email: email, otp: otp),
    );
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (user) => AuthAuthenticated(user),
    );
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    final result = await _repository.googleSignIn();
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (user) => AuthAuthenticated(user),
    );
  }

  /// Send a password reset email.
  Future<void> forgotPassword({required String email}) async {
    state = const AuthLoading();
    final result = await _repository.forgotPassword(email: email);
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (_) => const AuthPasswordResetSent(),
    );
  }

  /// Sign out.
  Future<void> logout() async {
    state = const AuthLoading();
    final result = await _logoutUseCase();
    result.fold(
      (failure) => state = AuthError(failure.message, failure: failure),
      (_) => state = const AuthInitial(),
    );
  }

  /// Reset the state back to initial (e.g., when navigating away).
  void resetState() {
    state = const AuthInitial();
  }
}
