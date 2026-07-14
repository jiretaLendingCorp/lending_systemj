// lib/features/borrowers/domain/usecases/get_borrower_profile_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:jireta_loan/features/borrowers/domain/repositories/borrower_repository.dart';

class GetBorrowerProfileUseCase {
  final LenderRepository _repository;

  GetBorrowerProfileUseCase({required LenderRepository repository})
      : _repository = repository;

  Future<Either<Failure, LenderProfile>> call() {
    return _repository.getProfile();
  }
}
