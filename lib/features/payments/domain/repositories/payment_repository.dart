// lib/features/payments/domain/repositories/payment_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';

abstract class PaymentRepository {
  Future<Either<Failure, Payment>> create({
    required String loanId,
    required double amount,
    required PaymentMethod method,
  });

  Future<Either<Failure, PaymentListResult>> list({
    String? loanId,
    String? lenderId,
    String? status,
    String? method,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PaymentListResult>> getByLoanId(
    String loanId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Payment>> detail(String paymentId);

  Future<Either<Failure, Payment>> verify(String paymentId);

  Future<Either<Failure, Payment>> reject(String paymentId, {String? reason});
}

class PaymentListResult {
  final List<Payment> payments;
  final int total;

  const PaymentListResult({
    required this.payments,
    required this.total,
  });
}
