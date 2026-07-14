import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';

/// Abstract interface for authentication operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
/// All methods return [Either]<[Failure], T> so that error handling
/// is explicit at the call site.
abstract class AuthRepository {
  /// Sign in with email and password.
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Sign up a new user.
  ///
  /// Self-registration is limited to borrower and rider roles.
  Future<Either<Failure, User>> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  });

  /// Send an OTP to the user's email for verification.
  Future<Either<Failure, void>> otpSend({required String email});

  /// Verify an OTP code.
  Future<Either<Failure, User>> otpVerify({
    required String email,
    required String otp,
  });

  /// Sign in with Google OAuth.
  Future<Either<Failure, User>> googleSignIn();

  /// Refresh the current access token.
  Future<Either<Failure, String>> refreshToken();

  /// Sign out and clear session.
  Future<Either<Failure, void>> logout();

  /// Send a password reset email.
  Future<Either<Failure, void>> forgotPassword({required String email});

  /// Reset password using recovery token.
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });
}
