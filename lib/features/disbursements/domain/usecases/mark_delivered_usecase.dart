// lib/features/disbursements/domain/usecases/mark_delivered_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';
import 'package:jireta_loan/features/disbursements/domain/repositories/disbursement_repository.dart';

class MarkDeliveredUseCase {
  final DisbursementRepository _repository;

  MarkDeliveredUseCase({required DisbursementRepository repository})
      : _repository = repository;

  Future<Either<Failure, Disbursement>> call(
    MarkDeliveredParams params,
  ) async {
    if (params.latitude == 0.0 && params.longitude == 0.0) {
      return Future.value(const Left(ValidationFailure(
        message: 'GPS coordinates are required to mark as delivered.',
        fieldErrors: {
          'gps': 'Please enable location services and try again.',
        },
      )));
    }

    if (params.latitude < -90 || params.latitude > 90) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid GPS latitude.',
        fieldErrors: {'latitude': 'Latitude must be between -90 and 90.'},
      )));
    }

    if (params.longitude < -180 || params.longitude > 180) {
      return Future.value(const Left(ValidationFailure(
        message: 'Invalid GPS longitude.',
        fieldErrors: {'longitude': 'Longitude must be between -180 and 180.'},
      )));
    }

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
