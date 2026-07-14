import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/users/data/datasources/user_remote_datasource.dart'
    hide UserListResult;
import 'package:lendflow/features/users/domain/entities/user_management.dart';
import 'package:lendflow/features/users/domain/repositories/user_repository.dart'
    as domain;

/// Concrete implementation of [UserRepository].
///
/// Delegates to [UserRemoteDataSource] for all network operations
/// and maps [AppException] subtypes to [Failure] subtypes.
class UserRepositoryImpl implements domain.UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl({required UserRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, domain.UserListResult>> list({
    String? role,
    String? search,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _remoteDataSource.list(
        role: role,
        search: search,
        isActive: isActive,
        page: page,
        pageSize: pageSize,
      );
      return Right(domain.UserListResult(
        users: result.users,
        total: result.total,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
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
  Future<Either<Failure, UserManagement>> create({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? branchId,
  }) async {
    try {
      final user = await _remoteDataSource.create(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        branchId: branchId,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
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

  @override
  Future<Either<Failure, UserManagement>> deactivate(String userId) async {
    try {
      final user = await _remoteDataSource.deactivate(userId);
      return Right(user);
    } on AuthException catch (e) {
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
  Future<Either<Failure, UserManagement>> reactivate(String userId) async {
    try {
      final user = await _remoteDataSource.reactivate(userId);
      return Right(user);
    } on AuthException catch (e) {
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
  Future<Either<Failure, void>> resetPassword(String userId) async {
    try {
      await _remoteDataSource.resetPassword(userId);
      return const Right(null);
    } on AuthException catch (e) {
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
  Future<Either<Failure, void>> forceLogout(String userId) async {
    try {
      await _remoteDataSource.forceLogout(userId);
      return const Right(null);
    } on AuthException catch (e) {
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
  Future<Either<Failure, UserManagement>> updateRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      final user = await _remoteDataSource.updateRole(
        userId: userId,
        newRole: newRole,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
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
