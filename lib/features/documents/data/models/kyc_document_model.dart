// lib/features/documents/data/models/kyc_document_model.dart
import 'package:jireta_loan/features/documents/domain/entities/kyc_document.dart';

class KycDocumentModel extends KycDocument {
  const KycDocumentModel({
    required super.id,
    required super.lenderId,
    required super.documentType,
    required super.fileUrl,
    super.status = DocumentStatus.pending,
    super.reviewedBy,
    super.reviewedAt,
    required super.createdAt,
  });

  factory KycDocumentModel.fromJson(Map<String, dynamic> json) {
    return KycDocumentModel(
      id: json['id'] as String,
      lenderId:
          json['lender_id'] as String? ?? json['lenderId'] as String? ?? '',
      documentType: DocumentType.fromString(
        json['document_type'] as String? ??
            json['documentType'] as String?,
      ),
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      status: DocumentStatus.fromString(
        json['status'] as String?,
      ),
      reviewedBy:
          json['reviewed_by'] as String? ?? json['reviewedBy'] as String?,
      reviewedAt: _parseDateTime(
        json['reviewed_at'] ?? json['reviewedAt'],
      ),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lender_id': lenderId,
      'document_type': documentType.toApiString(),
      'file_url': fileUrl,
      'status': status.toApiString(),
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  KycDocumentModel copyWith({
    String? id,
    String? lenderId,
    DocumentType? documentType,
    String? fileUrl,
    DocumentStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return KycDocumentModel(
      id: id ?? this.id,
      lenderId: lenderId ?? this.lenderId,
      documentType: documentType ?? this.documentType,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
