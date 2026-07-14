// lib/features/notifications/domain/repositories/notification_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> list({
    String? type,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, AppNotification>> markRead(String notificationId);

  Future<Either<Failure, void>> markAllRead();
}
