import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:lendflow/features/borrowers/domain/repositories/borrower_repository.dart';

/// Get borrower profile use case.
///
/// Fetches the authenticated borrower's profile from the repository.
class GetBorrowerProfileUseCase {
  final BorrowerRepository _repository;

  GetBorrowerProfileUseCase({required BorrowerRepository repository})
      : _repository = repository;

  Future<Either<Failure, BorrowerProfile>> call() {
    return _repository.getProfile();
  }
}
