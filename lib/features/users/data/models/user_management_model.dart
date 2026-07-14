import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/users/domain/entities/user_management.dart';

/// Data-layer representation of [UserManagement], with JSON serialization.
class UserManagementModel extends UserManagement {
  const UserManagementModel({
    required super.id,
    required super.email,
    super.phone,
    required super.role,
    required super.fullName,
    super.isActive = true,
    super.lastLoginAt,
    required super.createdAt,
    super.branchId,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) {
    return UserManagementModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      lastLoginAt: _parseDateTime(json['last_login_at'] ?? json['lastLoginAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      branchId: json['branch_id'] as String? ?? json['branchId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role.toApiString(),
      'full_name': fullName,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'branch_id': branchId,
    };
  }

  UserManagementModel copyWith({
    String? id,
    String? email,
    String? phone,
    UserRole? role,
    String? fullName,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    String? branchId,
  }) {
    return UserManagementModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      branchId: branchId ?? this.branchId,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
