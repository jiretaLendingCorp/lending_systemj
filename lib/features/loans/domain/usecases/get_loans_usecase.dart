// lib/features/loans/domain/usecases/get_loans_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/loans/domain/repositories/loan_repository.dart';

class GetLoansUseCase {
  final LoanRepository _repository;

  GetLoansUseCase({required LoanRepository repository})
      : _repository = repository;

  Future<Either<Failure, LoanListResult>> call(GetLoansParams params) {
    return _repository.list(
      status: params.status,
      page: params.page,
      pageSize: params.pageSize,
      search: params.search,
    );
  }
}

class GetLoansParams extends Equatable {
  final String? status;
  final int page;
  final int pageSize;
  final String? search;

  const GetLoansParams({
    this.status,
    this.page = 1,
    this.pageSize = 20,
    this.search,
  });

  @override
  List<Object?> get props => [status, page, pageSize, search];
}
