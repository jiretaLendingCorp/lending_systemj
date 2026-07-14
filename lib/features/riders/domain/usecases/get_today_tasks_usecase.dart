import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/riders/domain/entities/rider_task.dart';
import 'package:lendflow/features/riders/domain/repositories/rider_repository.dart';

/// Get today's assigned tasks for the authenticated rider.
///
/// Returns a list of [RiderTask]s filtered by the optional [type]
/// parameter (disbursement or collection).
class GetTodayTasksUseCase {
  final RiderRepository _repository;

  GetTodayTasksUseCase({required RiderRepository repository})
      : _repository = repository;

  Future<Either<Failure, List<RiderTask>>> call(GetTodayTasksParams params) {
    return _repository.getTodayTasks(type: params.type);
  }
}

/// Parameters for the get today's tasks use case.
class GetTodayTasksParams extends Equatable {
  final String? type;

  const GetTodayTasksParams({this.type});

  @override
  List<Object?> get props => [type];
}
