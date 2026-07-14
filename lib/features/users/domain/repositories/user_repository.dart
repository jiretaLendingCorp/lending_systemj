// lib/features/users/domain/repositories/user_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/users/domain/entities/user_management.dart';

abstract class UserRepository {
  Future<Either<Failure, UserListResult>> list({
    String? role,
    String? search,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, UserManagement>> create({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? branchId,
  });

  Future<Either<Failure, UserManagement>> deactivate(String userId);

  Future<Either<Failure, UserManagement>> reactivate(String userId);

  Future<Either<Failure, void>> resetPassword(String userId);

  Future<Either<Failure, void>> forceLogout(String userId);

  Future<Either<Failure, UserManagement>> updateRole({
    required String userId,
    required String newRole,
  });
}

class UserListResult {
  final List<UserManagement> users;
  final int total;

  const UserListResult({
    required this.users,
    required this.total,
  });
}
