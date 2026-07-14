// lib/features/lenders/domain/usecases/get_borrower_profile_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/lenders/domain/entities/lender_profile.dart';
import 'package:jireta_loan/features/lenders/domain/repositories/borrower_repository.dart';

class GetBorrowerProfileUseCase {
  final LenderRepository _repository;

  GetBorrowerProfileUseCase({required LenderRepository repository})
      : _repository = repository;

  Future<Either<Failure, LenderProfile>> call() {
    return _repository.getProfile();
  }
}
