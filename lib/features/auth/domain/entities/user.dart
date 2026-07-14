// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

enum UserRole {
  headManager,
  employee,
  rider,
  lender;

  static UserRole fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'head_manager' => UserRole.headManager,
      'employee' => UserRole.employee,
      'rider' => UserRole.rider,
      'lender' => UserRole.lender,
      _ => UserRole.lender,
    };
  }

  String toApiString() => switch (this) {
        UserRole.headManager => 'head_manager',
        UserRole.employee => 'employee',
        UserRole.rider => 'rider',
        UserRole.lender => 'lender',
      };

  String get label => switch (this) {
        UserRole.headManager => 'Head Manager',
        UserRole.employee => 'Employee',
        UserRole.rider => 'Rider',
        UserRole.lender => 'Lender',
      };

  String get shortLabel => switch (this) {
        UserRole.headManager => 'HM',
        UserRole.employee => 'EMP',
        UserRole.rider => 'RDR',
        UserRole.lender => 'LNDR',
      };

  bool get canApproveLoans =>
      this == UserRole.headManager || this == UserRole.employee;

  bool get canViewAllLoans =>
      this == UserRole.headManager || this == UserRole.employee;

  bool get canManageUsers => this == UserRole.headManager;

  bool get canViewAuditLogs => this == UserRole.headManager;

  bool get canManageSystemSettings => this == UserRole.headManager;

  bool get isSelfRegistrable =>
      this == UserRole.lender || this == UserRole.rider;
}

class User extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final UserRole role;
  final String fullName;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.fullName,
    this.isActive = true,
    required this.createdAt,
  });

  String get displayName => fullName.isNotEmpty ? fullName : email;

  String get initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isHeadManager => role == UserRole.headManager;

  bool get isEmployee => role == UserRole.employee;

  bool get isRider => role == UserRole.rider;

  bool get isLender => role == UserRole.lender;

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        role,
        fullName,
        isActive,
        createdAt,
      ];
}
