// lib/features/collections/domain/usecases/mark_collected_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/collections/domain/repositories/collection_repository.dart';

class MarkCollectedUseCase {
  final CollectionRepository _repository;

  MarkCollectedUseCase({required CollectionRepository repository})
      : _repository = repository;

  Future<Either<Failure, dynamic>> call(
    MarkCollectedParams params,
  ) async {
    if (params.latitude == 0.0 && params.longitude == 0.0) {
      return Future.value(const Left(ValidationFailure(
        message: 'GPS coordinates are required to mark as collected.',
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
