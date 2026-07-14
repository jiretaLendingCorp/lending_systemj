// lib/features/loans/domain/usecases/approve_loan_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/domain/repositories/loan_repository.dart';

class ApproveLoanUseCase {
  final LoanRepository _repository;

  ApproveLoanUseCase({required LoanRepository repository})
      : _repository = repository;

  Future<Either<Failure, Loan>> call(ApproveLoanParams params) {
    return _repository.approve(params.loanId);
  }
}

class ApproveLoanParams extends Equatable {
  final String loanId;

  const ApproveLoanParams({required this.loanId});

  @override
  List<Object?> get props => [loanId];
}
