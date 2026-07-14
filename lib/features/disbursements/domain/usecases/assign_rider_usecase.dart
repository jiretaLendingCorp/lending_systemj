import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/disbursements/domain/entities/disbursement.dart';
import 'package:lendflow/features/disbursements/domain/repositories/disbursement_repository.dart';

/// Assign rider to disbursement use case.
///
/// Validates that the disbursement is in a state that allows
/// rider assignment (pending or assigned) before proceeding.
class AssignRiderUseCase {
  final DisbursementRepository _repository;

  AssignRiderUseCase({required DisbursementRepository repository})
      : _repository = repository;

  Future<Either<Failure, Disbursement>> call(
    AssignRiderParams params,
  ) async {
    // Validate rider ID
    if (params.riderId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Please select a rider to assign.',
        fieldErrors: {'rider_id': 'Rider selection is required.'},
      )));
    }

    // Validate disbursement ID
    if (params.disbursementId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Disbursement ID is required.',
        fieldErrors: {'disbursement_id': 'Disbursement ID is required.'},
      )));
    }

    return _repository.assignRider(
      disbursementId: params.disbursementId,
      riderId: params.riderId,
    );
  }
}

/// Parameters for the assign rider use case.
class AssignRiderParams extends Equatable {
  final String disbursementId;
  final String riderId;

  const AssignRiderParams({
    required this.disbursementId,
    required this.riderId,
  });

  @override
  List<Object?> get props => [disbursementId, riderId];
}
