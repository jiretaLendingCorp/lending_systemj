// lib/features/riders/domain/usecases/gps_checkin_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';
import 'package:jireta_loan/features/riders/domain/repositories/rider_repository.dart';

class GpsCheckinUseCase {
  final RiderRepository _repository;

  GpsCheckinUseCase({required RiderRepository repository})
      : _repository = repository;

  Future<Either<Failure, RiderTask>> call(GpsCheckinParams params) {
    if (params.latitude < -90 || params.latitude > 90) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid latitude. Must be between -90 and 90.',
        fieldErrors: {'latitude': 'Must be between -90 and 90.'},
      )));
    }

    if (params.longitude < -180 || params.longitude > 180) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid longitude. Must be between -180 and 180.',
        fieldErrors: {'longitude': 'Must be between -180 and 180.'},
      )));
    }

    if (params.latitude == 0.0 && params.longitude == 0.0) {
      return Future.value(const Left(ValidationFailure(
        message: 'GPS coordinates appear invalid. Please ensure location services are enabled.',
        fieldErrors: {'gps': 'Coordinates cannot be 0, 0.'},
      )));
    }

    return _repository.gpsCheckin(
      taskId: params.taskId,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class GpsCheckinParams extends Equatable {
  final String taskId;
  final double latitude;
  final double longitude;

  const GpsCheckinParams({
    required this.taskId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [taskId, latitude, longitude];
}
