import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/disbursements/domain/entities/disbursement.dart';
import 'package:lendflow/features/disbursements/domain/repositories/disbursement_repository.dart';

/// Mark disbursement as delivered use case (rider action).
///
/// Validates that GPS coordinates are provided before marking
/// the disbursement as delivered. GPS proof is required for
/// audit and compliance purposes.
class MarkDeliveredUseCase {
  final DisbursementRepository _repository;

  MarkDeliveredUseCase({required DisbursementRepository repository})
      : _repository = repository;

  Future<Either<Failure, Disbursement>> call(
    MarkDeliveredParams params,
  ) async {
    // Validate GPS coordinates
    if (params.latitude == 0.0 && params.longitude == 0.0) {
      return Future.value(const Left(ValidationFailure(
        message: 'GPS coordinates are required to mark as delivered.',
        fieldErrors: {
          'gps': 'Please enable location services and try again.',
        },
      )));
    }

    // Validate latitude range
    if (params.latitude < -90 || params.latitude > 90) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid GPS latitude.',
        fieldErrors: {'latitude': 'Latitude must be between -90 and 90.'},
      )));
    }

    // Validate longitude range
    if (params.longitude < -180 || params.longitude > 180) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid GPS longitude.',
        fieldErrors: {'longitude': 'Longitude must be between -180 and 180.'},
      )));
    }

    // Validate disbursement ID
    if (params.disbursementId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Disbursement ID is required.',
      )));
    }

    return _repository.markDelivered(
      disbursementId: params.disbursementId,
      latitude: params.latitude,
      longitude: params.longitude,
      receiptPhotoUrl: params.receiptPhotoUrl,
    );
  }
}

/// Parameters for the mark delivered use case.
class MarkDeliveredParams extends Equatable {
  final String disbursementId;
  final double latitude;
  final double longitude;
  final String? receiptPhotoUrl;

  const MarkDeliveredParams({
    required this.disbursementId,
    required this.latitude,
    required this.longitude,
    this.receiptPhotoUrl,
  });

  @override
  List<Object?> get props => [
        disbursementId,
        latitude,
        longitude,
        receiptPhotoUrl,
      ];
}
