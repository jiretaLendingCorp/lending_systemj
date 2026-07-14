import 'package:equatable/equatable.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';

/// Admin-level user management entity.
///
/// Extends the core [User] concept with admin-specific fields
/// like last login, branch assignment, and active status toggle.
class UserManagement extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final UserRole role;
  final String fullName;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final String? branchId;

  const UserManagement({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.fullName,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    this.branchId,
  });

  /// Display name with email fallback.
  String get displayName => fullName.isNotEmpty ? fullName : email;

  /// Whether the user has ever logged in.
  bool get hasLoggedIn => lastLoginAt != null;

  /// Role label for display.
  String get roleLabel => role.label;

  /// Status label for display.
  String get statusLabel => isActive ? 'Active' : 'Inactive';

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        role,
        fullName,
        isActive,
        lastLoginAt,
        createdAt,
        branchId,
      ];
}
