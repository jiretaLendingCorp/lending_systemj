// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  });

  Future<Either<Failure, void>> otpSend({required String phone});

  Future<Either<Failure, User>> otpVerify({
    required String phone,
    required String otp,
  });

  Future<Either<Failure, User>> googleSignIn();

  Future<Either<Failure, String>> refreshToken();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });
}
