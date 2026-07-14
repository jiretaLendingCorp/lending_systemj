import 'package:lendflow/features/collections/domain/entities/collection.dart';

/// Data-layer representation of a [Collection], with JSON serialization.
class CollectionModel extends Collection {
  const CollectionModel({
    required super.id,
    required super.loanId,
    required super.borrowerId,
    super.method = CollectionMethod.cash,
    super.status = CollectionStatus.pending,
    super.assignedRiderId,
    super.riderName,
    required super.amount,
    super.gpsLatitude,
    super.gpsLongitude,
    super.collectedAt,
    super.photoReceiptUrl,
    required super.createdAt,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String? ?? json['loanId'] as String? ?? '',
      borrowerId:
          json['borrower_id'] as String? ?? json['borrowerId'] as String? ?? '',
      method: CollectionMethod.fromString(
        json['method'] as String? ?? json['collection_method'] as String?,
      ),
      status: CollectionStatus.fromString(json['status'] as String?),
      assignedRiderId: json['assigned_rider_id'] as String? ??
          json['assignedRiderId'] as String?,
      riderName:
          json['rider_name'] as String? ?? json['riderName'] as String?,
      amount: _parseDouble(json['amount']),
      gpsLatitude: _parseDouble(json['gps_latitude'] ?? json['gpsLatitude']),
      gpsLongitude:
          _parseDouble(json['gps_longitude'] ?? json['gpsLongitude']),
      collectedAt:
          _parseDateTime(json['collected_at'] ?? json['collectedAt']),
      photoReceiptUrl: json['photo_receipt_url'] as String? ??
          json['photoReceiptUrl'] as String?,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'borrower_id': borrowerId,
      'method': method.toApiString(),
      'status': status.toApiString(),
      'assigned_rider_id': assignedRiderId,
      'rider_name': riderName,
      'amount': amount,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'collected_at': collectedAt?.toIso8601String(),
      'photo_receipt_url': photoReceiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CollectionModel copyWith({
    String? id,
    String? loanId,
    String? borrowerId,
    CollectionMethod? method,
    CollectionStatus? status,
    String? assignedRiderId,
    String? riderName,
    double? amount,
    double? gpsLatitude,
    double? gpsLongitude,
    DateTime? collectedAt,
    String? photoReceiptUrl,
    DateTime? createdAt,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      borrowerId: borrowerId ?? this.borrowerId,
      method: method ?? this.method,
      status: status ?? this.status,
      assignedRiderId: assignedRiderId ?? this.assignedRiderId,
      riderName: riderName ?? this.riderName,
      amount: amount ?? this.amount,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      collectedAt: collectedAt ?? this.collectedAt,
      photoReceiptUrl: photoReceiptUrl ?? this.photoReceiptUrl,
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
