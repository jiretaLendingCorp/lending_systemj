import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/disbursements/domain/entities/disbursement.dart';

/// Abstract interface for disbursement operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class DisbursementRepository {
  /// List disbursements with optional filters and pagination.
  Future<Either<Failure, DisbursementListResult>> list({
    String? status,
    String? method,
    String? riderId,
    int page = 1,
    int pageSize = 20,
  });

  /// Get detailed information about a specific disbursement.
  Future<Either<Failure, Disbursement>> detail(String disbursementId);

  /// Assign a rider to a disbursement (manager/admin).
  Future<Either<Failure, Disbursement>> assignRider({
    required String disbursementId,
    required String riderId,
  });

  /// Mark a disbursement as delivered (rider action).
  ///
  /// Requires GPS coordinates from the rider's device.
  Future<Either<Failure, Disbursement>> markDelivered({
    required String disbursementId,
    required double latitude,
    required double longitude,
    String? receiptPhotoUrl,
  });

  /// Mark a disbursement as in transit (rider starts delivery).
  Future<Either<Failure, Disbursement>> markInTransit(
    String disbursementId,
  );

  /// Mark a disbursement as failed.
  Future<Either<Failure, Disbursement>> markFailed(
    String disbursementId, {
    String? reason,
  });

  /// Get available riders for assignment.
  Future<Either<Failure, List<RiderInfo>>> getAvailableRiders();
}

/// Paginated result for disbursement list queries.
class DisbursementListResult {
  final List<Disbursement> disbursements;
  final int total;

  const DisbursementListResult({
    required this.disbursements,
    required this.total,
  });
}

/// Simplified rider info for assignment.
class RiderInfo {
  final String id;
  final String name;
  final String? phone;
  final bool isAvailable;
  final int activeDeliveries;

  const RiderInfo({
    required this.id,
    required this.name,
    this.phone,
    this.isAvailable = true,
    this.activeDeliveries = 0,
  });
}
