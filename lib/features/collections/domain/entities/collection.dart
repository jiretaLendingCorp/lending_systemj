// lib/features/collections/domain/entities/collection.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        CollectionMethod.gcash => LucideIcons.smartphone,
        CollectionMethod.office => LucideIcons.store,
        CollectionMethod.cash => LucideIcons.banknote,
      };
}

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
        CollectionStatus.pending => LucideIcons.clock,
        CollectionStatus.assigned => LucideIcons.user,
        CollectionStatus.inTransit => LucideIcons.truck,
        CollectionStatus.collected => LucideIcons.circleCheck,
        CollectionStatus.failed => LucideIcons.circleAlert,
      };
}

class Collection extends Equatable {
  final String id;
  final String loanId;
  final String lenderId;
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
    required this.lenderId,
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

  bool get hasRiderAssigned => assignedRiderId != null;

  bool get hasGpsCoordinates =>
      gpsLatitude != null && gpsLongitude != null;

  bool get isCollected => status == CollectionStatus.collected;

  bool get requiresRider => method == CollectionMethod.cash;

  @override
  List<Object?> get props => [
        id,
        loanId,
        lenderId,
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
