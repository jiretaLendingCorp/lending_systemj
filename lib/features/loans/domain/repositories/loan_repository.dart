import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/loans/domain/entities/loan_schedule.dart';

/// Abstract interface for loan operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class LoanRepository {
  /// List loans with optional status filter and pagination.
  Future<Either<Failure, LoanListResult>> list({
    String? status,
    int page = 1,
    int pageSize = 20,
    String? search,
  });

  /// Create a new loan application.
  Future<Either<Failure, Loan>> create({
    required double principal,
    required int termDays,
    required ScheduleType scheduleType,
    required String coMakerFullName,
    required String coMakerPhone,
    required String coMakerAddress,
    required String coMakerRelationship,
  });

  /// Get detailed information about a specific loan.
  Future<Either<Failure, Loan>> detail(String loanId);

  /// Get the repayment schedule for a specific loan.
  Future<Either<Failure, List<LoanSchedule>>> schedule(String loanId);

  /// Approve a loan (manager/admin only).
  Future<Either<Failure, Loan>> approve(String loanId);

  /// Reject a loan (manager/admin only).
  Future<Either<Failure, Loan>> reject(String loanId, {String? reason});

  /// Compute penalty for an overdue loan.
  Future<Either<Failure, Loan>> computePenalty(String loanId);
}

/// Paginated result for loan list queries.
class LoanListResult {
  final List<Loan> loans;
  final int total;

  const LoanListResult({
    required this.loans,
    required this.total,
  });
}
