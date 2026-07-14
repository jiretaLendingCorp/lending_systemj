import 'package:equatable/equatable.dart';

/// KYC document type classification.
enum DocumentType {
  governmentId,
  proofOfBilling,
  selfie,
  proofOfIncome;

  static DocumentType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'government_id' || 'governmentid' => DocumentType.governmentId,
      'proof_of_billing' || 'proofofbilling' => DocumentType.proofOfBilling,
      'selfie' => DocumentType.selfie,
      'proof_of_income' || 'proofincome' => DocumentType.proofOfIncome,
      _ => DocumentType.governmentId,
    };
  }

  String toApiString() => switch (this) {
        DocumentType.governmentId => 'government_id',
        DocumentType.proofOfBilling => 'proof_of_billing',
        DocumentType.selfie => 'selfie',
        DocumentType.proofOfIncome => 'proof_of_income',
      };

  String get label => switch (this) {
        DocumentType.governmentId => 'Government ID',
        DocumentType.proofOfBilling => 'Proof of Billing',
        DocumentType.selfie => 'Selfie Photo',
        DocumentType.proofOfIncome => 'Proof of Income',
      };

  String get description => switch (this) {
        DocumentType.governmentId =>
          'Valid government-issued ID (passport, driver\'s license, etc.)',
        DocumentType.proofOfBilling =>
          'Recent utility bill or bank statement with your address',
        DocumentType.selfie =>
          'Clear selfie photo for identity verification',
        DocumentType.proofOfIncome =>
          'Payslip, COE, or ITR as proof of income',
      };

  IconData get icon => switch (this) {
        DocumentType.governmentId => Icons.badge_outlined,
        DocumentType.proofOfBilling => Icons.receipt_long_outlined,
        DocumentType.selfie => Icons.face_outlined,
        DocumentType.proofOfIncome => Icons.attach_money_outlined,
      };
}

/// KYC document verification status.
enum DocumentStatus {
  pending,
  verified,
  rejected;

  static DocumentStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => DocumentStatus.pending,
      'verified' => DocumentStatus.verified,
      'rejected' => DocumentStatus.rejected,
      _ => DocumentStatus.pending,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        DocumentStatus.pending => 'Pending Review',
        DocumentStatus.verified => 'Verified',
        DocumentStatus.rejected => 'Rejected',
      };

  bool get isVerified => this == DocumentStatus.verified;
  bool get isPending => this == DocumentStatus.pending;
  bool get isRejected => this == DocumentStatus.rejected;
}

/// Core entity representing a KYC document uploaded by a borrower.
///
/// Documents are stored in Supabase private storage buckets and
/// accessed via signed URLs for security.
class KycDocument extends Equatable {
  final String id;
  final String borrowerId;
  final DocumentType documentType;
  final String fileUrl;
  final DocumentStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const KycDocument({
    required this.id,
    required this.borrowerId,
    required this.documentType,
    required this.fileUrl,
    this.status = DocumentStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  /// Whether the document needs to be re-uploaded.
  bool get needsReupload => status == DocumentStatus.rejected;

  /// Whether the document is still being reviewed.
  bool get isUnderReview => status == DocumentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        borrowerId,
        documentType,
        fileUrl,
        status,
        reviewedBy,
        reviewedAt,
        createdAt,
      ];
}
