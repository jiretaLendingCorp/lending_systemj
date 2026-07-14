import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/notifications/domain/entities/app_notification.dart';

/// Abstract interface for notification operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class NotificationRepository {
  /// List notifications with optional type filter and pagination.
  Future<Either<Failure, List<AppNotification>>> list({
    String? type,
    int page = 1,
    int pageSize = 20,
  });

  /// Mark a specific notification as read.
  Future<Either<Failure, AppNotification>> markRead(String notificationId);

  /// Mark all notifications as read for the authenticated user.
  Future<Either<Failure, void>> markAllRead();
}
