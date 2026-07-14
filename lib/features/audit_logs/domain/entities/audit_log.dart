// lib/features/audit_logs/domain/entities/audit_log.dart
import 'package:equatable/equatable.dart';

class AuditLog extends Equatable {
  final String id;
  final String userId;
  final String userRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? oldValue;
  final String? newValue;
  final String ipAddress;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.action,
    this.entityType,
    this.entityId,
    this.oldValue,
    this.newValue,
    this.ipAddress = '',
    required this.createdAt,
  });

  bool get hasDiff => oldValue != null || newValue != null;

  String get actionCategory {
    final lower = action.toLowerCase();
    if (lower.contains('create') || lower.contains('add')) return 'create';
    if (lower.contains('update') || lower.contains('change') || lower.contains('modify')) return 'update';
    if (lower.contains('delete') || lower.contains('remove') || lower.contains('deactivate')) return 'delete';
    if (lower.contains('login') || lower.contains('auth') || lower.contains('logout')) return 'auth';
    if (lower.contains('approve') || lower.contains('reject')) return 'approval';
    return 'other';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userRole,
        action,
        entityType,
        entityId,
        oldValue,
        newValue,
        ipAddress,
        createdAt,
      ];
}
