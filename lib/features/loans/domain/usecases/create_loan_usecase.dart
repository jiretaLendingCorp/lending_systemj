// lib/features/loans/domain/usecases/create_loan_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/domain/repositories/loan_repository.dart';

class CreateLoanUseCase {
  final LoanRepository _repository;

  CreateLoanUseCase({required LoanRepository repository})
      : _repository = repository;

  Future<Either<Failure, Loan>> call(CreateLoanParams params) {
    if (params.principal < 3000) {
      return Future.value(const Left(ValidationFailure(
        message: 'Minimum loan amount is ₱3,000.',
        fieldErrors: {'principal': 'Minimum loan amount is ₱3,000.'},
      )));
    }
    if (params.principal > 500000) {
      return Future.value(const Left(ValidationFailure(
        message: 'Maximum loan amount is ₱500,000.',
        fieldErrors: {'principal': 'Maximum loan amount is ₱500,000.'},
      )));
    }

    return _repository.create(
      principal: params.principal,
      termDays: params.termDays,
      scheduleType: params.scheduleType,
      coMakerFullName: params.coMakerFullName,
      coMakerPhone: params.coMakerPhone,
      coMakerAddress: params.coMakerAddress,
      coMakerRelationship: params.coMakerRelationship,
    );
  }
}

class CreateLoanParams extends Equatable {
  final double principal;
  final int termDays;
  final ScheduleType scheduleType;
  final String coMakerFullName;
  final String coMakerPhone;
  final String coMakerAddress;
  final String coMakerRelationship;

  const CreateLoanParams({
    required this.principal,
    required this.termDays,
    this.scheduleType = ScheduleType.monthly,
    required this.coMakerFullName,
    required this.coMakerPhone,
    required this.coMakerAddress,
    required this.coMakerRelationship,
  });

  @override
  List<Object?> get props => [
        principal,
        termDays,
        scheduleType,
        coMakerFullName,
        coMakerPhone,
        coMakerAddress,
        coMakerRelationship,
      ];
}
