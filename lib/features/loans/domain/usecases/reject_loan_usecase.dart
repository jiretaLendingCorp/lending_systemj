import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/loans/domain/repositories/loan_repository.dart';

/// Reject loan use case (manager/admin only).
///
/// Transitions a loan from [underReview] to [rejected] status.
/// An optional reason can be provided to explain the rejection.
class RejectLoanUseCase {
  final LoanRepository _repository;

  RejectLoanUseCase({required LoanRepository repository})
      : _repository = repository;

  Future<Either<Failure, Loan>> call(RejectLoanParams params) {
    return _repository.reject(params.loanId, reason: params.reason);
  }
}

/// Parameters for the reject loan use case.
class RejectLoanParams extends Equatable {
  final String loanId;
  final String? reason;

  const RejectLoanParams({
    required this.loanId,
    this.reason,
  });

  @override
  List<Object?> get props => [loanId, reason];
}
