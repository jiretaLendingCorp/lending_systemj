// lib/features/disbursements/domain/repositories/disbursement_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';

abstract class DisbursementRepository {
  Future<Either<Failure, DisbursementListResult>> list({
    String? status,
    String? method,
    String? riderId,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Disbursement>> detail(String disbursementId);

  Future<Either<Failure, Disbursement>> assignRider({
    required String disbursementId,
    required String riderId,
  });

  Future<Either<Failure, Disbursement>> markDelivered({
    required String disbursementId,
    required double latitude,
    required double longitude,
    String? receiptPhotoUrl,
  });

  Future<Either<Failure, Disbursement>> markInTransit(
    String disbursementId,
  );

  Future<Either<Failure, Disbursement>> markFailed(
    String disbursementId, {
    String? reason,
  });

  Future<Either<Failure, List<RiderInfo>>> getAvailableRiders();
}

class DisbursementListResult {
  final List<Disbursement> disbursements;
  final int total;

  const DisbursementListResult({
    required this.disbursements,
    required this.total,
  });
}

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
