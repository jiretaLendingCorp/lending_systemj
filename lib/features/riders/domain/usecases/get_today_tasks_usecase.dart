// lib/features/riders/domain/usecases/get_today_tasks_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';
import 'package:jireta_loan/features/riders/domain/repositories/rider_repository.dart';

class GetTodayTasksUseCase {
  final RiderRepository _repository;

  GetTodayTasksUseCase({required RiderRepository repository})
      : _repository = repository;

  Future<Either<Failure, List<RiderTask>>> call(GetTodayTasksParams params) {
    return _repository.getTodayTasks(type: params.type);
  }
}

class GetTodayTasksParams extends Equatable {
  final String? type;

  const GetTodayTasksParams({this.type});

  @override
  List<Object?> get props => [type];
}
