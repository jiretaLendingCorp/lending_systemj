import 'package:lendflow/features/audit_logs/domain/entities/audit_log.dart';

/// Data-layer representation of [AuditLog], with JSON serialization.
class AuditLogModel extends AuditLog {
  const AuditLogModel({
    required super.id,
    required super.userId,
    required super.userRole,
    required super.action,
    super.entityType,
    super.entityId,
    super.oldValue,
    super.newValue,
    super.ipAddress = '',
    required super.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      userRole: json['user_role'] as String? ?? json['userRole'] as String? ?? '',
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? json['entityType'] as String?,
      entityId: json['entity_id'] as String? ?? json['entityId'] as String?,
      oldValue: json['old_value'] as String? ?? json['oldValue'] as String?,
      newValue: json['new_value'] as String? ?? json['newValue'] as String?,
      ipAddress: json['ip_address'] as String? ?? json['ipAddress'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_role': userRole,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_value': oldValue,
      'new_value': newValue,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
