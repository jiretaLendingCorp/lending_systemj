// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';
import 'package:jireta_loan/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      return Right(user);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        code: e.statusCode,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        code: e.statusCode,
        fieldErrors: e.fieldErrors,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.statusCode,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, User>> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final user = await _remoteDataSource.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      return Right(user);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        code: e.statusCode,
        requiresReAuth: e.requiresReAuth,
      ));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        code: e.statusCode,
        fieldErrors: e.fieldErrors,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.statusCode,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> otpSend({required String email}) async {
    try {
      await _remoteDataSource.otpSend(email: email);
      return const Right(null);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> otpVerify({
    required String email,
    required String otp,
  }) async {
    try {
      final user = await _remoteDataSource.otpVerify(
        email: email,
        otp: otp,
      );
      return Right(user);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> googleSignIn() async {
    try {
      final user = await _remoteDataSource.googleSignIn();
      return Right(user);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final token = await _remoteDataSource.refreshToken();
      return Right(token);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    try {
      await _remoteDataSource.forgotPassword(email: email);
      return const Right(null);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return const Right(null);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
