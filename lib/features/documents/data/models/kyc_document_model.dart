import 'package:lendflow/features/documents/domain/entities/kyc_document.dart';

/// Data-layer representation of a [KycDocument], with JSON serialization.
class KycDocumentModel extends KycDocument {
  const KycDocumentModel({
    required super.id,
    required super.borrowerId,
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
      borrowerId:
          json['borrower_id'] as String? ?? json['borrowerId'] as String? ?? '',
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
      'borrower_id': borrowerId,
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
    String? borrowerId,
    DocumentType? documentType,
    String? fileUrl,
    DocumentStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return KycDocumentModel(
      id: id ?? this.id,
      borrowerId: borrowerId ?? this.borrowerId,
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
