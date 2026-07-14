import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/riders/domain/entities/rider_task.dart';
import 'package:lendflow/features/riders/domain/repositories/rider_repository.dart';

/// Mark a task as completed (delivered or collected).
///
/// Dispatches to either [markDelivered] or [markCollected] based on
/// the [completionType] parameter. Validates that the amount is
/// provided for collection tasks.
class CompleteTaskUseCase {
  final RiderRepository _repository;

  CompleteTaskUseCase({required RiderRepository repository})
      : _repository = repository;

  Future<Either<Failure, RiderTask>> call(CompleteTaskParams params) {
    // Validate amount for collection tasks
    if (params.completionType == TaskCompletionType.collected &&
        params.amount <= 0) {
      return Future.value(const Left(ValidationFailure(
        message: 'Collection amount must be greater than zero.',
        fieldErrors: {'amount': 'Must be greater than zero.'},
      )));
    }

    // Validate GPS coordinates
    if (params.latitude == 0.0 && params.longitude == 0.0) {
      return Future.value(const Left(ValidationFailure(
        message: 'GPS coordinates appear invalid. Please ensure location services are enabled.',
        fieldErrors: {'gps': 'Coordinates cannot be 0, 0.'},
      )));
    }

    if (params.completionType == TaskCompletionType.delivered) {
      return _repository.markDelivered(
        taskId: params.taskId,
        latitude: params.latitude,
        longitude: params.longitude,
        photoReceiptUrl: params.photoReceiptUrl,
      );
    }

    return _repository.markCollected(
      taskId: params.taskId,
      amount: params.amount!,
      latitude: params.latitude,
      longitude: params.longitude,
      photoReceiptUrl: params.photoReceiptUrl,
    );
  }
}

/// Type of task completion.
enum TaskCompletionType {
  delivered,
  collected;
}

/// Parameters for the complete task use case.
class CompleteTaskParams extends Equatable {
  final String taskId;
  final TaskCompletionType completionType;
  final double? amount;
  final double latitude;
  final double longitude;
  final String? photoReceiptUrl;

  const CompleteTaskParams({
    required this.taskId,
    required this.completionType,
    this.amount,
    required this.latitude,
    required this.longitude,
    this.photoReceiptUrl,
  });

  @override
  List<Object?> get props => [
        taskId,
        completionType,
        amount,
        latitude,
        longitude,
        photoReceiptUrl,
      ];
}
