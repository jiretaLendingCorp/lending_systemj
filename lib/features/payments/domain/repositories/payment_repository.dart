import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/payments/domain/entities/payment.dart';

/// Abstract interface for payment operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class PaymentRepository {
  /// Create a new payment for a loan.
  Future<Either<Failure, Payment>> create({
    required String loanId,
    required double amount,
    required PaymentMethod method,
  });

  /// List payments with optional filters and pagination.
  Future<Either<Failure, PaymentListResult>> list({
    String? loanId,
    String? borrowerId,
    String? status,
    String? method,
    int page = 1,
    int pageSize = 20,
  });

  /// Get payments for a specific loan.
  Future<Either<Failure, PaymentListResult>> getByLoanId(
    String loanId, {
    int page = 1,
    int pageSize = 20,
  });

  /// Get detailed information about a specific payment.
  Future<Either<Failure, Payment>> detail(String paymentId);

  /// Verify a payment (admin/manager action).
  Future<Either<Failure, Payment>> verify(String paymentId);

  /// Reject a payment (admin/manager action).
  Future<Either<Failure, Payment>> reject(String paymentId, {String? reason});
}

/// Paginated result for payment list queries.
class PaymentListResult {
  final List<Payment> payments;
  final int total;

  const PaymentListResult({
    required this.payments,
    required this.total,
  });
}
