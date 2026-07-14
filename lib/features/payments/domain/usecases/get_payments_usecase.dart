import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/payments/domain/repositories/payment_repository.dart';

/// Get payment history for a loan use case.
///
/// Returns a paginated list of payments for the specified loan.
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
      borrowerId: params.borrowerId,
      status: params.status,
      method: params.method,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

/// Parameters for the get payments use case.
class GetPaymentsParams extends Equatable {
  final String? loanId;
  final String? borrowerId;
  final String? status;
  final String? method;
  final int page;
  final int pageSize;

  const GetPaymentsParams({
    this.loanId,
    this.borrowerId,
    this.status,
    this.method,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [
        loanId,
        borrowerId,
        status,
        method,
        page,
        pageSize,
      ];
}
