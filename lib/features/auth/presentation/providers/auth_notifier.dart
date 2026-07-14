// lib/features/auth/presentation/providers/auth_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:jireta_loan/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';
import 'package:jireta_loan/features/auth/domain/repositories/auth_repository.dart';
import 'package:jireta_loan/features/auth/domain/usecases/login_usecase.dart';
import 'package:jireta_loan/features/auth/domain/usecases/logout_usecase.dart';
import 'package:jireta_loan/features/auth/domain/usecases/otp_verify_usecase.dart';
import 'package:jireta_loan/features/auth/domain/usecases/signup_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

sealed class AuthFeatureState {
  const AuthFeatureState();
}

class AuthInitial extends AuthFeatureState {
  const AuthInitial();
}

class AuthFeatureLoading extends AuthFeatureState {
  const AuthFeatureLoading();
}

class AuthFeatureAuthenticated extends AuthFeatureState {
  final User user;
  const AuthFeatureAuthenticated(this.user);
}

class AuthOtpSent extends AuthFeatureState {
  final String email;
  const AuthOtpSent(this.email);
}

class AuthPasswordResetSent extends AuthFeatureState {
  const AuthPasswordResetSent();
}

class AuthError extends AuthFeatureState {
  final String message;
  final Failure? failure;
  const AuthError(this.message, {this.failure});
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    supabaseClient: Supabase.instance.client,
    dio: ref.watch(dioProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(repository: ref.watch(authRepositoryProvider));
});

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  return SignupUseCase(repository: ref.watch(authRepositoryProvider));
});

final otpVerifyUseCaseProvider = Provider<OtpVerifyUseCase>((ref) {
  return OtpVerifyUseCase(repository: ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(repository: ref.watch(authRepositoryProvider));
});

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

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthFeatureLoading();
    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (user) => AuthFeatureAuthenticated(user),
    );
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    state = const AuthFeatureLoading();
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

  Future<void> sendOtp({required String email}) async {
    state = const AuthFeatureLoading();
    final result = await _repository.otpSend(email: email);
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (_) => AuthOtpSent(email),
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = const AuthFeatureLoading();
    final result = await _otpVerifyUseCase(
      OtpVerifyParams(email: email, otp: otp),
    );
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (user) => AuthFeatureAuthenticated(user),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AuthFeatureLoading();
    final result = await _repository.googleSignIn();
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (user) => AuthFeatureAuthenticated(user),
    );
  }

  Future<void> forgotPassword({required String email}) async {
    state = const AuthFeatureLoading();
    final result = await _repository.forgotPassword(email: email);
    state = result.fold(
      (failure) => AuthError(failure.message, failure: failure),
      (_) => const AuthPasswordResetSent(),
    );
  }

  Future<void> logout() async {
    state = const AuthFeatureLoading();
    final result = await _logoutUseCase();
    result.fold(
      (failure) => state = AuthError(failure.message, failure: failure),
      (_) => state = const AuthInitial(),
    );
  }

  void resetState() {
    state = const AuthInitial();
  }
}
