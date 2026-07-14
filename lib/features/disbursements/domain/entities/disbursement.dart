import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Disbursement method: how the loan funds are delivered.
enum DisbursementMethod {
  gcash,
  office,
  cash;

  static DisbursementMethod fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'gcash' => DisbursementMethod.gcash,
      'office' => DisbursementMethod.office,
      'cash' => DisbursementMethod.cash,
      _ => DisbursementMethod.cash,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        DisbursementMethod.gcash => 'GCash',
        DisbursementMethod.office => 'Office Pickup',
        DisbursementMethod.cash => 'Cash Delivery',
      };

  String get description => switch (this) {
        DisbursementMethod.gcash => 'Disbursed via GCash through Xendit',
        DisbursementMethod.office => 'Pickup at the branch office',
        DisbursementMethod.cash => 'Rider delivers cash to borrower',
      };

  IconData get iconData => switch (this) {
        DisbursementMethod.gcash => Icons.phone_android_rounded,
        DisbursementMethod.office => Icons.store_rounded,
        DisbursementMethod.cash => Icons.local_shipping_rounded,
      };
}

/// Disbursement status lifecycle:
///   pending → assigned → in_transit → delivered
///   pending → assigned → in_transit → failed
///   pending → failed (unassignable)
enum DisbursementStatus {
  pending,
  assigned,
  inTransit,
  delivered,
  failed;

  static DisbursementStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => DisbursementStatus.pending,
      'assigned' => DisbursementStatus.assigned,
      'in_transit' => DisbursementStatus.inTransit,
      'delivered' => DisbursementStatus.delivered,
      'failed' => DisbursementStatus.failed,
      _ => DisbursementStatus.pending,
    };
  }

  String toApiString() => switch (this) {
        DisbursementStatus.inTransit => 'in_transit',
        _ => name,
      };

  String get label => switch (this) {
        DisbursementStatus.pending => 'Pending',
        DisbursementStatus.assigned => 'Assigned',
        DisbursementStatus.inTransit => 'In Transit',
        DisbursementStatus.delivered => 'Delivered',
        DisbursementStatus.failed => 'Failed',
      };

  bool get isTerminal =>
      this == DisbursementStatus.delivered ||
      this == DisbursementStatus.failed;

  bool get isActionable =>
      this == DisbursementStatus.pending ||
      this == DisbursementStatus.assigned;

  IconData get iconData => switch (this) {
        DisbursementStatus.pending => Icons.schedule_rounded,
        DisbursementStatus.assigned => Icons.person_rounded,
        DisbursementStatus.inTransit => Icons.local_shipping_rounded,
        DisbursementStatus.delivered => Icons.check_circle_rounded,
        DisbursementStatus.failed => Icons.error_rounded,
      };
}

/// Core disbursement entity representing loan fund delivery.
///
/// This is the domain-level representation. Data-layer concerns
/// (JSON serialization) live in [DisbursementModel].
class Disbursement extends Equatable {
  final String id;
  final String loanId;
  final DisbursementMethod method;
  final DisbursementStatus status;
  final String? assignedRiderId;
  final String? riderName;
  final String? xenditDisbursementId;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final DateTime? deliveredAt;
  final String? receiptUrl;
  final DateTime createdAt;

  const Disbursement({
    required this.id,
    required this.loanId,
    this.method = DisbursementMethod.cash,
    this.status = DisbursementStatus.pending,
    this.assignedRiderId,
    this.riderName,
    this.xenditDisbursementId,
    this.gpsLatitude,
    this.gpsLongitude,
    this.deliveredAt,
    this.receiptUrl,
    required this.createdAt,
  });

  /// Whether a rider has been assigned.
  bool get hasRiderAssigned => assignedRiderId != null;

  /// Whether GPS coordinates are available.
  bool get hasGpsCoordinates =>
      gpsLatitude != null && gpsLongitude != null;

  /// Whether the disbursement was delivered.
  bool get isDelivered => status == DisbursementStatus.delivered;

  /// Whether this requires a rider (cash or office method).
  bool get requiresRider =>
      method == DisbursementMethod.cash ||
      method == DisbursementMethod.office;

  @override
  List<Object?> get props => [
        id,
        loanId,
        method,
        status,
        assignedRiderId,
        riderName,
        xenditDisbursementId,
        gpsLatitude,
        gpsLongitude,
        deliveredAt,
        receiptUrl,
        createdAt,
      ];
}
