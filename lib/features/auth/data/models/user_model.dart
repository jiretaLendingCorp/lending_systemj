// lib/features/auth/data/models/user_model.dart
import 'package:jireta_loan/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.phone,
    required super.role,
    required super.fullName,
    super.isActive,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phone_number'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  factory UserModel.fromSupabaseUser(Map<String, dynamic> userJson) {
    final metadata = userJson['user_metadata'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final appMetadata = userJson['app_metadata'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    return UserModel(
      id: userJson['id'] as String? ?? '',
      email: userJson['email'] as String? ?? '',
      phone: metadata['phone'] as String?,
      role: UserRole.fromString(
        appMetadata['role'] as String? ?? metadata['role'] as String?,
      ),
      fullName: metadata['full_name'] as String? ?? metadata['fullName'] as String? ?? '',
      isActive: userJson['banned'] == null || userJson['banned'] == false,
      createdAt: _parseDateTime(userJson['created_at']),
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    UserRole? role,
    String? fullName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
