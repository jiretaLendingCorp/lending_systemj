// lib/features/riders/data/repositories/rider_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/riders/data/datasources/rider_remote_datasource.dart';
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';
import 'package:jireta_loan/features/riders/domain/repositories/rider_repository.dart';

class RiderRepositoryImpl implements RiderRepository {
  final RiderRemoteDataSource _remoteDataSource;

  RiderRepositoryImpl({required RiderRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<RiderTask>>> getTodayTasks({String? type}) async {
    try {
      final tasks = await _remoteDataSource.getTodayTasks(type: type);
      return Right(tasks);
    } on AppAuthException catch (e) {
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
  Future<Either<Failure, RiderTask>> gpsCheckin({
    required String taskId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final task = await _remoteDataSource.gpsCheckin(
        taskId: taskId,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(task);
    } on AppAuthException catch (e) {
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
  Future<Either<Failure, RiderTask>> markDelivered({
    required String taskId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    try {
      final task = await _remoteDataSource.markDelivered(
        taskId: taskId,
        latitude: latitude,
        longitude: longitude,
        photoReceiptUrl: photoReceiptUrl,
      );
      return Right(task);
    } on AppAuthException catch (e) {
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
  Future<Either<Failure, RiderTask>> markCollected({
    required String taskId,
    required double amount,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    try {
      final task = await _remoteDataSource.markCollected(
        taskId: taskId,
        amount: amount,
        latitude: latitude,
        longitude: longitude,
        photoReceiptUrl: photoReceiptUrl,
      );
      return Right(task);
    } on AppAuthException catch (e) {
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
  Future<Either<Failure, List<RiderTask>>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final tasks = await _remoteDataSource.getHistory(
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      );
      return Right(tasks);
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
}
