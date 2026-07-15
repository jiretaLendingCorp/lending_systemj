// lib/features/documents/domain/entities/kyc_document.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        DocumentType.governmentId => LucideIcons.badge,
        DocumentType.proofOfBilling => LucideIcons.receipt,
        DocumentType.selfie => LucideIcons.smile,
        DocumentType.proofOfIncome => LucideIcons.dollarSign,
      };
}

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

class KycDocument extends Equatable {
  final String id;
  final String lenderId;
  final DocumentType documentType;
  final String fileUrl;
  final DocumentStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const KycDocument({
    required this.id,
    required this.lenderId,
    required this.documentType,
    required this.fileUrl,
    this.status = DocumentStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  bool get needsReupload => status == DocumentStatus.rejected;

  bool get isUnderReview => status == DocumentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        lenderId,
        documentType,
        fileUrl,
        status,
        reviewedBy,
        reviewedAt,
        createdAt,
      ];
}
