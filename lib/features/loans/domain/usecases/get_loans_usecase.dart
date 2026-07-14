import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/loans/domain/repositories/loan_repository.dart';

/// Get loans use case: retrieves a paginated list of loans.
///
/// Supports optional status filtering. Admin/manager users see
/// all loans; borrower users see only their own (enforced server-side).
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

/// Parameters for the get loans use case.
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
