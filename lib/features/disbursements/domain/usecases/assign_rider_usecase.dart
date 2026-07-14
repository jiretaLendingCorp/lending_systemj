// lib/features/disbursements/domain/usecases/assign_rider_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';
import 'package:jireta_loan/features/disbursements/domain/repositories/disbursement_repository.dart';

class AssignRiderUseCase {
  final DisbursementRepository _repository;

  AssignRiderUseCase({required DisbursementRepository repository})
      : _repository = repository;

  Future<Either<Failure, Disbursement>> call(
    AssignRiderParams params,
  ) async {
    if (params.riderId.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        message: 'Please select a rider to assign.',
        fieldErrors: {'rider_id': 'Rider selection is required.'},
      )));
    }

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
