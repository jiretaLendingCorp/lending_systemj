// lib/features/lenders/domain/entities/lender_profile.dart
import 'package:equatable/equatable.dart';

enum KycStatus {
  pending,
  verified,
  rejected;

  static KycStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => KycStatus.pending,
      'verified' => KycStatus.verified,
      'rejected' => KycStatus.rejected,
      _ => KycStatus.pending,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        KycStatus.pending => 'Pending',
        KycStatus.verified => 'Verified',
        KycStatus.rejected => 'Rejected',
      };

  bool get isVerified => this == KycStatus.verified;

  bool get isPending => this == KycStatus.pending;

  bool get isRejected => this == KycStatus.rejected;
}

enum EmploymentType {
  employed,
  selfEmployed,
  freelancer,
  unemployed;

  static EmploymentType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'employed' => EmploymentType.employed,
      'self_employed' || 'self-employed' => EmploymentType.selfEmployed,
      'freelancer' => EmploymentType.freelancer,
      'unemployed' => EmploymentType.unemployed,
      _ => EmploymentType.employed,
    };
  }

  String toApiString() => switch (this) {
        EmploymentType.selfEmployed => 'self_employed',
        _ => name,
      };

  String get label => switch (this) {
        EmploymentType.employed => 'Employed',
        EmploymentType.selfEmployed => 'Self-Employed',
        EmploymentType.freelancer => 'Freelancer',
        EmploymentType.unemployed => 'Unemployed',
      };
}

class LenderProfile extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final DateTime? birthday;
  final EmploymentType employmentType;
  final double monthlyIncome;
  final KycStatus kycStatus;
  final DateTime createdAt;

  const LenderProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.birthday,
    this.employmentType = EmploymentType.employed,
    this.monthlyIncome = 0.0,
    this.kycStatus = KycStatus.pending,
    required this.createdAt,
  });

  bool get canApplyForLoan => kycStatus.isVerified;

  bool get isProfileComplete =>
      fullName.isNotEmpty &&
      phone.isNotEmpty &&
      email.isNotEmpty &&
      address.isNotEmpty &&
      birthday != null;

  String get displayName =>
      fullName.split(' ').first;

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        phone,
        email,
        address,
        birthday,
        employmentType,
        monthlyIncome,
        kycStatus,
        createdAt,
      ];
}
