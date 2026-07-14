// lib/features/users/domain/entities/user_management.dart
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';

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

  String get displayName => fullName.isNotEmpty ? fullName : email;

  bool get hasLoggedIn => lastLoginAt != null;

  String get roleLabel => role.label;

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
