import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/features/auth/data/models/user_model.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';

/// Remote data source for authentication operations.
///
/// All auth operations go through Supabase Auth, with some
/// operations also hitting the backend API for profile sync.
class AuthRemoteDataSource {
  final supabase.SupabaseClient _supabase;
  final Dio _dio;

  AuthRemoteDataSource({
    required supabase.SupabaseClient supabaseClient,
    required Dio dio,
  })  : _supabase = supabaseClient,
        _dio = dio;

  /// Sign in with email and password.
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
        throw const AuthException(
          message: 'Login failed. Please try again.',
          requiresReAuth: true,
        );
      }
      return _userFromSupabaseResponse(user);
    } on supabase.AuthException catch (e) {
      throw AuthException(
        message: _mapSupabaseAuthMessage(e.message),
        requiresReAuth: true,
      );
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  /// Sign up with email, password, and profile data.
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
        throw const AuthException(message: 'Signup failed. Please try again.');
      }
      return _userFromSupabaseResponse(user);
    } on supabase.AuthException catch (e) {
      throw AuthException(
        message: _mapSupabaseAuthMessage(e.message),
      );
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  /// Send an OTP to the user's email for verification.
  Future<void> otpSend({required String email}) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
      );
    } on supabase.AuthException catch (e) {
      if (e.message.contains('rate limit') || e.message.contains('too many')) {
        throw const AuthException(
          message: 'Too many OTP requests. Please wait before requesting again.',
          errorCode: 'OTP_RATE_LIMITED',
        );
      }
      throw AuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  /// Verify an OTP code sent to the user's email.
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
        throw const AuthException(
          message: 'Verification failed. Please try again.',
        );
      }
      return _userFromSupabaseResponse(user);
    } on supabase.AuthException catch (e) {
      throw AuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  /// Sign in with Google OAuth.
  Future<UserModel> googleSignIn() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AuthException(message: 'Google sign-in was cancelled.');
      }
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException(
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
        throw const AuthException(
          message: 'Google sign-in failed. Please try again.',
        );
      }
      return _userFromSupabaseResponse(user);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'Google sign-in error: $e');
    }
  }

  /// Refresh the current access token.
  Future<String> refreshToken() async {
    try {
      final response = await _supabase.auth.refreshSession();
      final session = response.session;
      if (session == null) {
        throw const AuthException(
          message: 'Session expired. Please sign in again.',
          tokenExpired: true,
          requiresReAuth: true,
        );
      }
      return session.accessToken;
    } on supabase.AuthException catch (e) {
      throw AuthException(
        message: _mapSupabaseAuthMessage(e.message),
        tokenExpired: true,
        requiresReAuth: true,
      );
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  /// Sign out and invalidate the current session.
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Even if server-side logout fails, we treat local
      // sign-out as successful.
    }
  }

  /// Send a password reset email to the given address.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  /// Reset the password using the recovery token from the email link.
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
      throw AuthException(message: _mapSupabaseAuthMessage(e.message));
    } catch (e) {
      throw _mapToAppException(e);
    }
  }

  /// Get the current authenticated user profile from the backend API.
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.authMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────

  /// Create a [UserModel] from a Supabase auth response user.
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

  /// Parse a UserRole from a string, defaulting to borrower.
  UserRole _parseUserRole(String? value) {
    return switch (value?.toLowerCase()) {
      'admin' => UserRole.admin,
      'manager' => UserRole.manager,
      'rider' => UserRole.rider,
      _ => UserRole.borrower,
    };
  }

  /// Parse a DateTime from various possible formats.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Map Supabase auth error messages to user-friendly messages.
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

  /// Map a generic exception to an [AppException] subtype.
  AppException _mapToAppException(Object error) {
    if (error is DioException) {
      return _mapDioException(error);
    }
    if (error is AppException) {
      return error;
    }
    return ServerException(message: error.toString());
  }

  /// Map a [DioException] to the appropriate [AppException] subtype.
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
          return const AuthException(
            message: 'Session expired. Please sign in again.',
            tokenExpired: true,
            requiresReAuth: true,
          );
        }
        if (statusCode == 403) {
          return const AuthException(
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
