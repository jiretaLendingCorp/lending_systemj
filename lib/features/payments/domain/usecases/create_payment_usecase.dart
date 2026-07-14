// lib/features/payments/domain/usecases/create_payment_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';
import 'package:jireta_loan/features/payments/domain/repositories/payment_repository.dart';

class CreatePaymentUseCase {
  final PaymentRepository _repository;

  CreatePaymentUseCase({required PaymentRepository repository})
      : _repository = repository;

  Future<Either<Failure, Payment>> call(CreatePaymentParams params) {
    if (params.amount < 100) {
      return Future.value(const Left(ValidationFailure(
        message: 'Minimum payment amount is ₱100.',
        fieldErrors: {'amount': 'Minimum payment amount is ₱100.'},
      )));
    }

    if (params.amount <= 0) {
      return Future.value(const Left(ValidationFailure(
        message: 'Payment amount must be greater than zero.',
        fieldErrors: {'amount': 'Payment amount must be greater than zero.'},
      )));
    }

    return _repository.create(
      loanId: params.loanId,
      amount: params.amount,
      method: params.method,
    );
  }
}

class CreatePaymentParams extends Equatable {
  final String loanId;
  final double amount;
  final PaymentMethod method;

  const CreatePaymentParams({
    required this.loanId,
    required this.amount,
    required this.method,
  });

  @override
  List<Object?> get props => [loanId, amount, method];
}
