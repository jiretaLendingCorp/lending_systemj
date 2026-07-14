import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/riders/domain/entities/rider_task.dart';
import 'package:lendflow/features/riders/domain/repositories/rider_repository.dart';

/// GPS check-in use case with coordinate validation.
///
/// Validates that the provided GPS coordinates are within the
/// acceptable range (latitude: -90 to 90, longitude: -180 to 180)
/// before sending the check-in request to the repository.
class GpsCheckinUseCase {
  final RiderRepository _repository;

  GpsCheckinUseCase({required RiderRepository repository})
      : _repository = repository;

  Future<Either<Failure, RiderTask>> call(GpsCheckinParams params) {
    // Validate latitude range (-90 to 90)
    if (params.latitude < -90 || params.latitude > 90) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid latitude. Must be between -90 and 90.',
        fieldErrors: {'latitude': 'Must be between -90 and 90.'},
      )));
    }

    // Validate longitude range (-180 to 180)
    if (params.longitude < -180 || params.longitude > 180) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid longitude. Must be between -180 and 180.',
        fieldErrors: {'longitude': 'Must be between -180 and 180.'},
      )));
    }

    // Validate coordinates are not exactly 0,0 (null island)
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

/// Parameters for the GPS check-in use case.
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
