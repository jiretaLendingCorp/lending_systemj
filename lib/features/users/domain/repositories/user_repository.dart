import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/users/domain/entities/user_management.dart';

/// Abstract repository for admin user management operations.
///
/// All methods return [Either<Failure, T>] to keep the domain layer
/// free of framework dependencies. Admin-only actions that modify
/// sensitive data require forced re-authentication.
abstract class UserRepository {
  /// List users with optional filters and pagination.
  Future<Either<Failure, UserListResult>> list({
    String? role,
    String? search,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  });

  /// Create a new user with role assignment.
  Future<Either<Failure, UserManagement>> create({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? branchId,
  });

  /// Deactivate a user account.
  Future<Either<Failure, UserManagement>> deactivate(String userId);

  /// Reactivate a deactivated user account.
  Future<Either<Failure, UserManagement>> reactivate(String userId);

  /// Reset a user's password (sends reset link).
  Future<Either<Failure, void>> resetPassword(String userId);

  /// Force logout a user from all sessions.
  Future<Either<Failure, void>> forceLogout(String userId);

  /// Update a user's role.
  Future<Either<Failure, UserManagement>> updateRole({
    required String userId,
    required String newRole,
  });
}

/// Paginated result for user list queries at the domain level.
class UserListResult {
  final List<UserManagement> users;
  final int total;

  const UserListResult({
    required this.users,
    required this.total,
  });
}
