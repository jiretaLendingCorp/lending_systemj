// lib/features/riders/domain/entities/rider_task.dart
import 'package:equatable/equatable.dart';

enum RiderTaskType {
  disbursement,
  collection;

  static RiderTaskType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'disbursement' => RiderTaskType.disbursement,
      'collection' => RiderTaskType.collection,
      _ => RiderTaskType.disbursement,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        RiderTaskType.disbursement => 'Disbursement',
        RiderTaskType.collection => 'Collection',
      };

  String get icon => switch (this) {
        RiderTaskType.disbursement => 'cash_out',
        RiderTaskType.collection => 'cash_in',
      };
}

enum RiderTaskStatus {
  pending,
  assigned,
  inTransit,
  completed,
  failed;

  static RiderTaskStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => RiderTaskStatus.pending,
      'assigned' => RiderTaskStatus.assigned,
      'in_transit' => RiderTaskStatus.inTransit,
      'completed' => RiderTaskStatus.completed,
      'failed' => RiderTaskStatus.failed,
      _ => RiderTaskStatus.pending,
    };
  }

  String toApiString() => switch (this) {
        RiderTaskStatus.inTransit => 'in_transit',
        _ => name,
      };

  String get label => switch (this) {
        RiderTaskStatus.pending => 'Pending',
        RiderTaskStatus.assigned => 'Assigned',
        RiderTaskStatus.inTransit => 'In Transit',
        RiderTaskStatus.completed => 'Completed',
        RiderTaskStatus.failed => 'Failed',
      };

  bool get isActive =>
      this == RiderTaskStatus.assigned ||
      this == RiderTaskStatus.inTransit;

  bool get isTerminal =>
      this == RiderTaskStatus.completed ||
      this == RiderTaskStatus.failed;
}

class RiderTask extends Equatable {
  final String id;
  final RiderTaskType type;
  final String lenderName;
  final String lenderAddress;
  final double amount;
  final RiderTaskStatus status;
  final String loanId;
  final double gpsLatitude;
  final double gpsLongitude;
  final DateTime? completedAt;
  final String? photoReceiptUrl;

  const RiderTask({
    required this.id,
    required this.type,
    required this.lenderName,
    required this.lenderAddress,
    required this.amount,
    this.status = RiderTaskStatus.pending,
    required this.loanId,
    this.gpsLatitude = 0.0,
    this.gpsLongitude = 0.0,
    this.completedAt,
    this.photoReceiptUrl,
  });

  bool get hasGpsCoordinates => gpsLatitude != 0.0 && gpsLongitude != 0.0;

  bool get isDisbursement => type == RiderTaskType.disbursement;

  bool get isCollection => type == RiderTaskType.collection;

  @override
  List<Object?> get props => [
        id,
        type,
        lenderName,
        lenderAddress,
        amount,
        status,
        loanId,
        gpsLatitude,
        gpsLongitude,
        completedAt,
        photoReceiptUrl,
      ];
}
