// lib/features/collections/domain/usecases/assign_rider_collection_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/collections/domain/repositories/collection_repository.dart';

class AssignRiderCollectionUseCase {
  final CollectionRepository _repository;

  AssignRiderCollectionUseCase({required CollectionRepository repository})
      : _repository = repository;

  Future<Either<Failure, dynamic>> call(
    AssignRiderCollectionParams params,
  ) async {
    if (params.riderId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Please select a rider to assign.',
        fieldErrors: {'rider_id': 'Rider selection is required.'},
      )));
    }

    if (params.collectionId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Collection ID is required.',
        fieldErrors: {'collection_id': 'Collection ID is required.'},
      )));
    }

    return _repository.assignRider(
      collectionId: params.collectionId,
      riderId: params.riderId,
    );
  }
}

class AssignRiderCollectionParams extends Equatable {
  final String collectionId;
  final String riderId;

  const AssignRiderCollectionParams({
    required this.collectionId,
    required this.riderId,
  });

  @override
  List<Object?> get props => [collectionId, riderId];
}
