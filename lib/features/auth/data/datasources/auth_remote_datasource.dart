// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/features/auth/data/models/user_model.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';

class AuthRemoteDataSource {
  final supabase.SupabaseClient _supabase;
  final Dio _dio;

  AuthRemoteDataSource({
    required supabase.SupabaseClient supabaseClient,
    required Dio dio,
  })  : _supabase = supabaseClient,
        _dio = dio;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AppAuthException(
          message: 'Login failed. Please try again.',
          requiresReAuth: true,
        );
      }
      return _userFromSupabaseResponse(user);
    } on supabase.AuthException catch (e) {
      throw AppAuthException(
        message: _mapSupabaseAuthMessage(e.message),
        requiresReAuth: true,
      );
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'role': role,
        },
      );
      final user = response.user;
      if (user == null) {
        throw const AppAuthException(message: 'Signup failed. Please try again.');
      }
      return _userFromSupabaseResponse(user);
    } on supabase.AuthException catch (e) {
      throw AppAuthException(
        message: _mapSupabaseAuthMessage(e.message),
      );
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  Future<void> otpSend({required String email}) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
      );
    } on supabase.AuthException catch (e) {
      if (e.message.contains('rate limit') || e.message.contains('too many')) {
        throw const AppAuthException(
          message: 'Too many OTP requests. Please wait before requesting again.',
          errorCode: 'OTP_RATE_LIMITED',
        );
      }
      throw AppAuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  Future<UserModel> otpVerify({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: otp.trim(),
        type: supabase.OtpType.signup,
      );
      final user = response.user;
      if (user == null) {
        throw const AppAuthException(
          message: 'Verification failed. Please try again.',
        );
      }
      return _userFromSupabaseResponse(user);
    } on supabase.AuthException catch (e) {
      throw AppAuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  Future<UserModel> googleSignIn() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AppAuthException(message: 'Google sign-in was cancelled.');
      }
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AppAuthException(
          message: 'Failed to obtain Google authentication token.',
        );
      }
      final response = await _supabase.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      final user = response.user;
      if (user == null) {
        throw const AppAuthException(
          message: 'Google sign-in failed. Please try again.',
        );
      }
      return _userFromSupabaseResponse(user);
    } on AppAuthException {
      rethrow;
    } catch (e) {
      throw AppAuthException(message: 'Google sign-in error: $e');
    }
  }

  Future<String> refreshToken() async {
    try {
      final response = await _supabase.auth.refreshSession();
      final session = response.session;
      if (session == null) {
        throw const AppAuthException(
          message: 'Session expired. Please sign in again.',
          tokenExpired: true,
          requiresReAuth: true,
        );
      }
      return session.accessToken;
    } on supabase.AuthException catch (e) {
      throw AppAuthException(
        message: _mapSupabaseAuthMessage(e.message),
        tokenExpired: true,
        requiresReAuth: true,
      );
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
      );
    } on supabase.AuthException catch (e) {
      throw AppAuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        token: token,
        type: supabase.OtpType.recovery,
      );
      await _supabase.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } on supabase.AuthException catch (e) {
      throw AppAuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.authMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }


  UserModel _userFromSupabaseResponse(supabase.User user) {
    final metadata = user.userMetadata;
    final appMetadata = user.appMetadata;
    final roleStr = appMetadata['role'] as String? ?? metadata?['role'] as String?;
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      phone: metadata?['phone'] as String?,
      role: _parseUserRole(roleStr),
      fullName: (metadata?['full_name'] ?? metadata?['fullName']) as String? ?? '',
      isActive: true,
      createdAt: _parseDateTime(user.createdAt) ?? DateTime.now(),
    );
  }

  UserRole _parseUserRole(String? value) {
    return switch (value?.toLowerCase()) {
      'head_manager' => UserRole.headManager,
      'employee' => UserRole.employee,
      'rider' => UserRole.rider,
      _ => UserRole.lender,
    };
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _mapSupabaseAuthMessage(String? message) {
    if (message == null) return 'An authentication error occurred.';
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('invalid login credentials') ||
        lowerMessage.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (lowerMessage.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (lowerMessage.contains('password should be')) {
      return 'Password does not meet the required criteria.';
    }
    if (lowerMessage.contains('rate limit')) {
      return 'Too many attempts. Please wait before trying again.';
    }
    if (lowerMessage.contains('otp has expired')) {
      return 'The verification code has expired. Please request a new one.';
    }
    if (lowerMessage.contains('invalid otp')) {
      return 'The verification code is incorrect. Please try again.';
    }
    if (lowerMessage.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return message;
  }

  AppException _mapToAppException(Object error) {
    if (error is DioException) {
      return _mapDioException(error);
    }
    if (error is AppException) {
      return error;
    }
    return ServerException(message: error.toString());
  }

  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please try again.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection. Please check your network.',
          isConnectionRefused: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return const AppAuthException(
            message: 'Session expired. Please sign in again.',
            tokenExpired: true,
            requiresReAuth: true,
          );
        }
        if (statusCode == 403) {
          return const AppAuthException(
            message: 'You do not have permission to perform this action.',
          );
        }
        if (statusCode == 400 || statusCode == 422) {
          final data = e.response?.data;
          final fieldErrors = <String, String>{};
          if (data is Map<String, dynamic>) {
            final errors = data['errors'] as Map<String, dynamic>?;
            if (errors != null) {
              errors.forEach((key, value) {
                fieldErrors[key] = value.toString();
              });
            }
          }
          return ValidationException(
            message: data?['message'] as String? ?? 'Validation error.',
            statusCode: statusCode,
            fieldErrors: fieldErrors,
          );
        }
        return ServerException(
          message: 'Server error occurred. Please try again later.',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Certificate verification failed.',
        );
      case DioExceptionType.unknown:
        return NetworkException(
          message: e.message ?? 'An unexpected error occurred.',
        );
    }
  }
}
