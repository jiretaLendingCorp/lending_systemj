// lib/features/loans/domain/usecases/reject_loan_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/domain/repositories/loan_repository.dart';

class RejectLoanUseCase {
  final LoanRepository _repository;

  RejectLoanUseCase({required LoanRepository repository})
      : _repository = repository;

  Future<Either<Failure, Loan>> call(RejectLoanParams params) {
    return _repository.reject(params.loanId, reason: params.reason);
  }
}

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
