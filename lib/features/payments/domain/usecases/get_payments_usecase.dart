// lib/features/payments/domain/usecases/get_payments_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/payments/domain/repositories/payment_repository.dart';

class GetPaymentsUseCase {
  final PaymentRepository _repository;

  GetPaymentsUseCase({required PaymentRepository repository})
      : _repository = repository;

  Future<Either<Failure, PaymentListResult>> call(
    GetPaymentsParams params,
  ) {
    if (params.loanId != null) {
      return _repository.getByLoanId(
        params.loanId!,
        page: params.page,
        pageSize: params.pageSize,
      );
    }

    return _repository.list(
      lenderId: params.lenderId,
      status: params.status,
      method: params.method,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class GetPaymentsParams extends Equatable {
  final String? loanId;
  final String? lenderId;
  final String? status;
  final String? method;
  final int page;
  final int pageSize;

  const GetPaymentsParams({
    this.loanId,
    this.lenderId,
    this.status,
    this.method,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [
        loanId,
        lenderId,
        status,
        method,
        page,
        pageSize,
      ];
}
