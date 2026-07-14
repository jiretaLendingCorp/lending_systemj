// lib/features/borrowers/domain/repositories/borrower_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';

abstract class LenderRepository {
  Future<Either<Failure, LenderProfile>> getProfile();

  Future<Either<Failure, LenderProfile>> updateProfile(
      Map<String, dynamic> data);

  Future<Either<Failure, List<Loan>>> getOwnLoans({
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, List<Payment>>> getOwnPayments({
    String? loanId,
    int page = 1,
    int pageSize = 20,
  });
}
