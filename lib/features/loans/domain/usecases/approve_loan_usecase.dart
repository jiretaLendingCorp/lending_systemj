import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/loans/domain/repositories/loan_repository.dart';

/// Approve loan use case (manager/admin only).
///
/// Transitions a loan from [underReview] to [approved] status.
/// Only managers and admins have the authority to approve loans.
class ApproveLoanUseCase {
  final LoanRepository _repository;

  ApproveLoanUseCase({required LoanRepository repository})
      : _repository = repository;

  Future<Either<Failure, Loan>> call(ApproveLoanParams params) {
    return _repository.approve(params.loanId);
  }
}

/// Parameters for the approve loan use case.
class ApproveLoanParams extends Equatable {
  final String loanId;

  const ApproveLoanParams({required this.loanId});

  @override
  List<Object?> get props => [loanId];
}
