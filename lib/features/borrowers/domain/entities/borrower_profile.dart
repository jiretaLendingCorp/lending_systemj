import 'package:equatable/equatable.dart';

/// KYC verification status for a borrower.
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

/// Employment type classification for borrowers.
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

/// Core entity representing a borrower's profile.
///
/// Contains personal information, employment details, and KYC status.
/// The borrower profile is linked to a user account via [userId].
class BorrowerProfile extends Equatable {
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

  const BorrowerProfile({
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

  /// Whether the borrower can apply for a loan.
  bool get canApplyForLoan => kycStatus.isVerified;

  /// Whether the borrower has completed their profile.
  bool get isProfileComplete =>
      fullName.isNotEmpty &&
      phone.isNotEmpty &&
      email.isNotEmpty &&
      address.isNotEmpty &&
      birthday != null;

  /// Display name (first name only from full name).
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
