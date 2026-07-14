// lib/features/riders/data/models/rider_task_model.dart
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';

class RiderTaskModel extends RiderTask {
  const RiderTaskModel({
    required super.id,
    required super.type,
    required super.lenderName,
    required super.lenderAddress,
    required super.amount,
    super.status = RiderTaskStatus.pending,
    required super.loanId,
    super.gpsLatitude = 0.0,
    super.gpsLongitude = 0.0,
    super.completedAt,
    super.photoReceiptUrl,
  });

  factory RiderTaskModel.fromJson(Map<String, dynamic> json) {
    return RiderTaskModel(
      id: json['id'] as String,
      type: RiderTaskType.fromString(
        json['type'] as String? ?? json['task_type'] as String?,
      ),
      lenderName: json['lender_name'] as String? ??
          json['lenderName'] as String? ??
          '',
      lenderAddress: json['lender_address'] as String? ??
          json['lenderAddress'] as String? ??
          '',
      amount: _parseDouble(json['amount']),
      status: RiderTaskStatus.fromString(
        json['status'] as String?,
      ),
      loanId: json['loan_id'] as String? ?? json['loanId'] as String? ?? '',
      gpsLatitude: _parseDouble(
        json['gps_latitude'] ?? json['gpsLatitude'] ?? json['latitude'],
        fallback: 0.0,
      ),
      gpsLongitude: _parseDouble(
        json['gps_longitude'] ?? json['gpsLongitude'] ?? json['longitude'],
        fallback: 0.0,
      ),
      completedAt: _parseDateTime(
        json['completed_at'] ?? json['completedAt'],
      ),
      photoReceiptUrl: json['photo_receipt_url'] as String? ??
          json['photoReceiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toApiString(),
      'lender_name': lenderName,
      'lender_address': lenderAddress,
      'amount': amount,
      'status': status.toApiString(),
      'loan_id': loanId,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'completed_at': completedAt?.toIso8601String(),
      'photo_receipt_url': photoReceiptUrl,
    };
  }

  RiderTaskModel copyWith({
    String? id,
    RiderTaskType? type,
    String? lenderName,
    String? lenderAddress,
    double? amount,
    RiderTaskStatus? status,
    String? loanId,
    double? gpsLatitude,
    double? gpsLongitude,
    DateTime? completedAt,
    String? photoReceiptUrl,
  }) {
    return RiderTaskModel(
      id: id ?? this.id,
      type: type ?? this.type,
      lenderName: lenderName ?? this.lenderName,
      lenderAddress: lenderAddress ?? this.lenderAddress,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      loanId: loanId ?? this.loanId,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      completedAt: completedAt ?? this.completedAt,
      photoReceiptUrl: photoReceiptUrl ?? this.photoReceiptUrl,
    );
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
