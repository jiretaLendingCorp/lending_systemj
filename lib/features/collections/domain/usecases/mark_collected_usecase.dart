import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/collections/domain/repositories/collection_repository.dart';

/// Mark collected use case (rider action).
///
/// Validates that GPS coordinates are provided before marking
/// the collection as collected. GPS proof is required for
/// audit and compliance purposes, same as disbursement delivery.
class MarkCollectedUseCase {
  final CollectionRepository _repository;

  MarkCollectedUseCase({required CollectionRepository repository})
      : _repository = repository;

  Future<Either<Failure, dynamic>> call(
    MarkCollectedParams params,
  ) async {
    // Validate GPS coordinates
    if (params.latitude == 0.0 && params.longitude == 0.0) {
      return Future.value(const Left(ValidationFailure(
        message: 'GPS coordinates are required to mark as collected.',
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

    // Validate collection ID
    if (params.collectionId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Collection ID is required.',
      )));
    }

    return _repository.markCollected(
      collectionId: params.collectionId,
      latitude: params.latitude,
      longitude: params.longitude,
      photoReceiptUrl: params.photoReceiptUrl,
    );
  }
}

/// Parameters for the mark collected use case.
class MarkCollectedParams extends Equatable {
  final String collectionId;
  final double latitude;
  final double longitude;
  final String? photoReceiptUrl;

  const MarkCollectedParams({
    required this.collectionId,
    required this.latitude,
    required this.longitude,
    this.photoReceiptUrl,
  });

  @override
  List<Object?> get props => [
        collectionId,
        latitude,
        longitude,
        photoReceiptUrl,
      ];
}
