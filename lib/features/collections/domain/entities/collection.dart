import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Collection method: how the payment is collected from the borrower.
enum CollectionMethod {
  gcash,
  office,
  cash;

  static CollectionMethod fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'gcash' => CollectionMethod.gcash,
      'office' => CollectionMethod.office,
      'cash' => CollectionMethod.cash,
      _ => CollectionMethod.cash,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        CollectionMethod.gcash => 'GCash',
        CollectionMethod.office => 'Office',
        CollectionMethod.cash => 'Cash',
      };

  String get description => switch (this) {
        CollectionMethod.gcash => 'Digital payment via GCash',
        CollectionMethod.office => 'Payment at the branch office',
        CollectionMethod.cash => 'Cash collection by rider',
      };

  IconData get iconData => switch (this) {
        CollectionMethod.gcash => Icons.phone_android_rounded,
        CollectionMethod.office => Icons.store_rounded,
        CollectionMethod.cash => Icons.payments_rounded,
      };
}

/// Collection status lifecycle:
///   pending → assigned → in_transit → collected
///   pending → assigned → in_transit → failed
///   pending → failed (unassignable)
enum CollectionStatus {
  pending,
  assigned,
  inTransit,
  collected,
  failed;

  static CollectionStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => CollectionStatus.pending,
      'assigned' => CollectionStatus.assigned,
      'in_transit' => CollectionStatus.inTransit,
      'collected' => CollectionStatus.collected,
      'failed' => CollectionStatus.failed,
      _ => CollectionStatus.pending,
    };
  }

  String toApiString() => switch (this) {
        CollectionStatus.inTransit => 'in_transit',
        _ => name,
      };

  String get label => switch (this) {
        CollectionStatus.pending => 'Pending',
        CollectionStatus.assigned => 'Assigned',
        CollectionStatus.inTransit => 'In Transit',
        CollectionStatus.collected => 'Collected',
        CollectionStatus.failed => 'Failed',
      };

  bool get isTerminal =>
      this == CollectionStatus.collected ||
      this == CollectionStatus.failed;

  bool get isActionable =>
      this == CollectionStatus.pending ||
      this == CollectionStatus.assigned;

  IconData get iconData => switch (this) {
        CollectionStatus.pending => Icons.schedule_rounded,
        CollectionStatus.assigned => Icons.person_rounded,
        CollectionStatus.inTransit => Icons.local_shipping_rounded,
        CollectionStatus.collected => Icons.check_circle_rounded,
        CollectionStatus.failed => Icons.error_rounded,
      };
}

/// Core collection entity representing a payment collection from a borrower.
///
/// This is the domain-level representation. Data-layer concerns
/// (JSON serialization) live in [CollectionModel].
class Collection extends Equatable {
  final String id;
  final String loanId;
  final String borrowerId;
  final CollectionMethod method;
  final CollectionStatus status;
  final String? assignedRiderId;
  final String? riderName;
  final double amount;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final DateTime? collectedAt;
  final String? photoReceiptUrl;
  final DateTime createdAt;

  const Collection({
    required this.id,
    required this.loanId,
    required this.borrowerId,
    this.method = CollectionMethod.cash,
    this.status = CollectionStatus.pending,
    this.assignedRiderId,
    this.riderName,
    required this.amount,
    this.gpsLatitude,
    this.gpsLongitude,
    this.collectedAt,
    this.photoReceiptUrl,
    required this.createdAt,
  });

  /// Whether a rider has been assigned.
  bool get hasRiderAssigned => assignedRiderId != null;

  /// Whether GPS coordinates are available.
  bool get hasGpsCoordinates =>
      gpsLatitude != null && gpsLongitude != null;

  /// Whether the collection was completed.
  bool get isCollected => status == CollectionStatus.collected;

  /// Whether this requires a rider (cash method).
  bool get requiresRider => method == CollectionMethod.cash;

  @override
  List<Object?> get props => [
        id,
        loanId,
        borrowerId,
        method,
        status,
        assignedRiderId,
        riderName,
        amount,
        gpsLatitude,
        gpsLongitude,
        collectedAt,
        photoReceiptUrl,
        createdAt,
      ];
}
