// lib/features/borrowers/data/models/borrower_profile_model.dart
import 'package:jireta_loan/features/borrowers/domain/entities/borrower_profile.dart';

class BorrowerProfileModel extends LenderProfile {
  const BorrowerProfileModel({
    required super.id,
    required super.userId,
    required super.fullName,
    super.phone = '',
    super.email = '',
    super.address = '',
    super.birthday,
    super.employmentType = EmploymentType.employed,
    super.monthlyIncome = 0.0,
    super.kycStatus = KycStatus.pending,
    required super.createdAt,
  });

  factory BorrowerProfileModel.fromJson(Map<String, dynamic> json) {
    return BorrowerProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      fullName: json['full_name'] as String? ??
          json['fullName'] as String? ??
          '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      birthday: _parseDateTime(json['birthday'] ?? json['birth_date']),
      employmentType: EmploymentType.fromString(
        json['employment_type'] as String? ?? json['employmentType'] as String?,
      ),
      monthlyIncome: _parseDouble(
        json['monthly_income'] ?? json['monthlyIncome'],
        fallback: 0.0,
      ),
      kycStatus: KycStatus.fromString(
        json['kyc_status'] as String? ?? json['kycStatus'] as String?,
      ),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'birthday': birthday?.toIso8601String(),
      'employment_type': employmentType.toApiString(),
      'monthly_income': monthlyIncome,
      'kyc_status': kycStatus.toApiString(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  BorrowerProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    DateTime? birthday,
    EmploymentType? employmentType,
    double? monthlyIncome,
    KycStatus? kycStatus,
    DateTime? createdAt,
  }) {
    return BorrowerProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      birthday: birthday ?? this.birthday,
      employmentType: employmentType ?? this.employmentType,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      kycStatus: kycStatus ?? this.kycStatus,
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
