// lib/features/notifications/data/repositories/notification_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:jireta_loan/features/notifications/domain/entities/app_notification.dart';
import 'package:jireta_loan/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl(
      {required NotificationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<AppNotification>>> list({
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final notifications = await _remoteDataSource.list(
        type: type,
        page: page,
        pageSize: pageSize,
      );
      return Right(notifications);
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
  Future<Either<Failure, AppNotification>> markRead(
      String notificationId) async {
    try {
      final notification =
          await _remoteDataSource.markRead(notificationId);
      return Right(notification);
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
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await _remoteDataSource.markAllRead();
      return const Right(null);
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
