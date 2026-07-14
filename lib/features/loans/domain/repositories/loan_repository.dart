// lib/features/loans/domain/repositories/loan_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan_schedule.dart';

abstract class LoanRepository {
  Future<Either<Failure, LoanListResult>> list({
    String? status,
    int page = 1,
    int pageSize = 20,
    String? search,
  });

  Future<Either<Failure, Loan>> create({
    required double principal,
    required int termDays,
    required ScheduleType scheduleType,
    required String coMakerFullName,
    required String coMakerPhone,
    required String coMakerAddress,
    required String coMakerRelationship,
  });

  Future<Either<Failure, Loan>> detail(String loanId);

  Future<Either<Failure, List<LoanSchedule>>> schedule(String loanId);

  Future<Either<Failure, Loan>> approve(String loanId);

  Future<Either<Failure, Loan>> reject(String loanId, {String? reason});

  Future<Either<Failure, Loan>> computePenalty(String loanId);
}

class LoanListResult {
  final List<Loan> loans;
  final int total;

  const LoanListResult({
    required this.loans,
    required this.total,
  });
}
