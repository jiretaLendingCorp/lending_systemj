import 'package:equatable/equatable.dart';

/// User role enumeration for LendFlow.
///
/// Roles determine access levels and available features:
/// - [admin]: Full system access, user management, settings
/// - [manager]: Loan approval, collections oversight, reporting
/// - [rider]: Collection routes, payment recording, location tracking
/// - [borrower]: Loan application, payment viewing, profile management
enum UserRole {
  admin,
  manager,
  rider,
  borrower;

  /// Parse a role string, defaulting to [borrower] if invalid.
  static UserRole fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'admin' => UserRole.admin,
      'manager' => UserRole.manager,
      'rider' => UserRole.rider,
      'borrower' => UserRole.borrower,
      _ => UserRole.borrower,
    };
  }

  /// Serialize to lowercase string for API/storage.
  String toApiString() => name;

  /// Human-readable display label.
  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.manager => 'Manager',
        UserRole.rider => 'Rider',
        UserRole.borrower => 'Borrower',
      };

  /// Whether this role can approve/reject loans.
  bool get canApproveLoans =>
      this == UserRole.admin || this == UserRole.manager;

  /// Whether this role can view all loans across borrowers.
  bool get canViewAllLoans =>
      this == UserRole.admin || this == UserRole.manager;

  /// Whether this role is available for self-registration.
  bool get isSelfRegistrable =>
      this == UserRole.borrower || this == UserRole.rider;
}

/// Core user entity representing an authenticated LendFlow user.
///
/// This is the domain-level representation. Data-layer concerns
/// (JSON serialization, Supabase mapping) live in [UserModel].
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

  /// Convenience getter for display name with fallback.
  String get displayName => fullName.isNotEmpty ? fullName : email;

  /// Whether this user has admin-level privileges.
  bool get isAdmin => role == UserRole.admin;

  /// Whether this user has manager-level privileges.
  bool get isManager => role == UserRole.manager;

  /// Whether this user is a rider.
  bool get isRider => role == UserRole.rider;

  /// Whether this user is a borrower.
  bool get isBorrower => role == UserRole.borrower;

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
