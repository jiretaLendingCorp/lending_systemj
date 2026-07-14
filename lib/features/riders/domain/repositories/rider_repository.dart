// lib/features/riders/domain/repositories/rider_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';

abstract class RiderRepository {
  Future<Either<Failure, List<RiderTask>>> getTodayTasks({String? type});

  Future<Either<Failure, RiderTask>> gpsCheckin({
    required String taskId,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, RiderTask>> markDelivered({
    required String taskId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  });

  Future<Either<Failure, RiderTask>> markCollected({
    required String taskId,
    required double amount,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  });

  Future<Either<Failure, List<RiderTask>>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  });
}
