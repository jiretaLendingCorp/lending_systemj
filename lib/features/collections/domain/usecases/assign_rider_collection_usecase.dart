import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/collections/domain/repositories/collection_repository.dart';

/// Assign rider for collection use case.
///
/// Validates that the rider ID and collection ID are provided
/// before delegating to the repository.
class AssignRiderCollectionUseCase {
  final CollectionRepository _repository;

  AssignRiderCollectionUseCase({required CollectionRepository repository})
      : _repository = repository;

  Future<Either<Failure, dynamic>> call(
    AssignRiderCollectionParams params,
  ) async {
    // Validate rider ID
    if (params.riderId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Please select a rider to assign.',
        fieldErrors: {'rider_id': 'Rider selection is required.'},
      )));
    }

    // Validate collection ID
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

/// Parameters for the assign rider collection use case.
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
