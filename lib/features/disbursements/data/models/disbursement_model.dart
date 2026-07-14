// lib/features/disbursements/data/models/disbursement_model.dart
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';

class DisbursementModel extends Disbursement {
  const DisbursementModel({
    required super.id,
    required super.loanId,
    super.method = DisbursementMethod.cash,
    super.status = DisbursementStatus.pending,
    super.assignedRiderId,
    super.riderName,
    super.xenditDisbursementId,
    super.gpsLatitude,
    super.gpsLongitude,
    super.deliveredAt,
    super.receiptUrl,
    required super.createdAt,
  });

  factory DisbursementModel.fromJson(Map<String, dynamic> json) {
    return DisbursementModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String? ?? json['loanId'] as String? ?? '',
      method: DisbursementMethod.fromString(
        json['method'] as String? ?? json['disbursement_method'] as String?,
      ),
      status: DisbursementStatus.fromString(json['status'] as String?),
      assignedRiderId: json['assigned_rider_id'] as String? ??
          json['assignedRiderId'] as String?,
      riderName:
          json['rider_name'] as String? ?? json['riderName'] as String?,
      xenditDisbursementId:
          json['xendit_disbursement_id'] as String? ??
              json['xenditDisbursementId'] as String?,
      gpsLatitude: _parseDouble(json['gps_latitude'] ?? json['gpsLatitude']),
      gpsLongitude:
          _parseDouble(json['gps_longitude'] ?? json['gpsLongitude']),
      deliveredAt: _parseDateTime(json['delivered_at'] ?? json['deliveredAt']),
      receiptUrl:
          json['receipt_url'] as String? ?? json['receiptUrl'] as String?,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'method': method.toApiString(),
      'status': status.toApiString(),
      'assigned_rider_id': assignedRiderId,
      'rider_name': riderName,
      'xendit_disbursement_id': xenditDisbursementId,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'delivered_at': deliveredAt?.toIso8601String(),
      'receipt_url': receiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DisbursementModel copyWith({
    String? id,
    String? loanId,
    DisbursementMethod? method,
    DisbursementStatus? status,
    String? assignedRiderId,
    String? riderName,
    String? xenditDisbursementId,
    double? gpsLatitude,
    double? gpsLongitude,
    DateTime? deliveredAt,
    String? receiptUrl,
    DateTime? createdAt,
  }) {
    return DisbursementModel(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      method: method ?? this.method,
      status: status ?? this.status,
      assignedRiderId: assignedRiderId ?? this.assignedRiderId,
      riderName: riderName ?? this.riderName,
      xenditDisbursementId:
          xenditDisbursementId ?? this.xenditDisbursementId,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
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
