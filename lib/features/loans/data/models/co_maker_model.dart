// lib/features/loans/data/models/co_maker_model.dart
import 'package:jireta_loan/features/loans/domain/entities/co_maker.dart';

class CoMakerModel extends CoMaker {
  const CoMakerModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.address,
    required super.relationship,
    super.consentAt,
  });

  factory CoMakerModel.fromJson(Map<String, dynamic> json) {
    return CoMakerModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      consentAt: _parseDateTime(json['consent_at'] ?? json['consentAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'relationship': relationship,
      'consent_at': consentAt?.toIso8601String(),
    };
  }

  CoMakerModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? address,
    String? relationship,
    DateTime? consentAt,
  }) {
    return CoMakerModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      relationship: relationship ?? this.relationship,
      consentAt: consentAt ?? this.consentAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
