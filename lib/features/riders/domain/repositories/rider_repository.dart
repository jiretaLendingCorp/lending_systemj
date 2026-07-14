import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/riders/domain/entities/rider_task.dart';

/// Abstract interface for rider task operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class RiderRepository {
  /// Fetch today's assigned tasks for the authenticated rider.
  Future<Either<Failure, List<RiderTask>>> getTodayTasks({String? type});

  /// Perform GPS check-in for a specific task.
  ///
  /// The server validates that the rider is within the allowed radius
  /// of the borrower's address before accepting the check-in.
  Future<Either<Failure, RiderTask>> gpsCheckin({
    required String taskId,
    required double latitude,
    required double longitude,
  });

  /// Mark a disbursement task as delivered.
  Future<Either<Failure, RiderTask>> markDelivered({
    required String taskId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  });

  /// Mark a collection task as collected.
  Future<Either<Failure, RiderTask>> markCollected({
    required String taskId,
    required double amount,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  });

  /// Fetch the rider's task history with optional date range.
  Future<Either<Failure, List<RiderTask>>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  });
}
