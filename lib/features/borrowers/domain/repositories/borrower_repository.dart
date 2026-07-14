import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/payments/domain/entities/payment.dart';

/// Abstract interface for borrower operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class BorrowerRepository {
  /// Get the authenticated borrower's profile.
  Future<Either<Failure, BorrowerProfile>> getProfile();

  /// Update the borrower's profile information.
  Future<Either<Failure, BorrowerProfile>> updateProfile(
      Map<String, dynamic> data);

  /// Get the borrower's own loans.
  Future<Either<Failure, List<Loan>>> getOwnLoans({
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  /// Get the borrower's own payment history.
  Future<Either<Failure, List<Payment>>> getOwnPayments({
    String? loanId,
    int page = 1,
    int pageSize = 20,
  });
}
