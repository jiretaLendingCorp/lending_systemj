import 'package:lendflow/features/auth/domain/entities/user.dart';

/// Data-layer representation of a [User], with JSON serialization.
///
/// Extends the domain entity so that it can be used interchangeably
/// wherever a [User] is expected, while adding `fromJson` / `toJson`
/// for API communication and local caching.
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

  /// Create a [UserModel] from a Supabase/API JSON map.
  ///
  /// Handles both snake_case (API) and camelCase (local) keys.
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

  /// Create a [UserModel] from Supabase auth user metadata.
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

  /// Serialize to a JSON map suitable for API requests.
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

  /// Create a copy with optional field overrides.
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

  /// Parse a DateTime from various possible formats.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
