import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/users/data/datasources/user_remote_datasource.dart';
import 'package:lendflow/features/users/data/repositories/user_repository_impl.dart';
import 'package:lendflow/features/users/domain/entities/user_management.dart';
import 'package:lendflow/features/users/domain/repositories/user_repository.dart'
    as domain;

// ─────────────────────────────────────────────────────────────────
// User management state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level user management state.
sealed class UserFeatureState {
  const UserFeatureState();
}

/// Initial state.
class UserInitial extends UserFeatureState {
  const UserInitial();
}

/// Users are being loaded.
class UsersLoading extends UserFeatureState {
  const UsersLoading();
}

/// Users loaded successfully.
class UsersLoaded extends UserFeatureState {
  final List<UserManagement> users;
  final int total;
  final String? activeRoleFilter;
  final String? searchQuery;
  final int currentPage;

  const UsersLoaded({
    required this.users,
    required this.total,
    this.activeRoleFilter,
    this.searchQuery,
    this.currentPage = 1,
  });

  /// Whether there are more pages to load.
  bool get hasMore => users.length < total;
}

/// User operation succeeded (create, deactivate, reset password, etc.).
class UserOperationSuccess extends UserFeatureState {
  final String message;
  final UserManagement? user;

  const UserOperationSuccess({
    required this.message,
    this.user,
  });
}

/// An error occurred.
class UserError extends UserFeatureState {
  final String message;
  final Failure? failure;

  const UserError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [UserRemoteDataSource].
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [UserRepository] implementation.
final userRepositoryProvider = Provider<domain.UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.watch(userRemoteDataSourceProvider),
  );
});

/// Provides the [UserNotifier] for user management screens.
final userFeatureProvider =
    StateNotifierProvider<UserNotifier, UserFeatureState>((ref) {
  return UserNotifier(
    repository: ref.watch(userRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// User notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing user management UI state.
class UserNotifier extends StateNotifier<UserFeatureState> {
  final domain.UserRepository _repository;

  UserNotifier({
    required domain.UserRepository repository,
  })  : _repository = repository,
        super(const UserInitial());

  /// Load users with optional role filter and search.
  Future<void> loadUsers({
    String? role,
    String? search,
    int page = 1,
  }) async {
    if (page == 1) {
      state = const UsersLoading();
    }

    final result = await _repository.list(
      role: role,
      search: search,
      page: page,
    );

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (userListResult) {
        final existingUsers = state is UsersLoaded && page > 1
            ? (state as UsersLoaded).users
            : <UserManagement>[];
        return UsersLoaded(
          users: [...existingUsers, ...userListResult.users],
          total: userListResult.total,
          activeRoleFilter: role,
          searchQuery: search,
          currentPage: page,
        );
      },
    );
  }

  /// Load more users (pagination).
  Future<void> loadMore() async {
    if (state is! UsersLoaded) return;
    final current = state as UsersLoaded;
    if (!current.hasMore) return;

    await loadUsers(
      role: current.activeRoleFilter,
      search: current.searchQuery,
      page: current.currentPage + 1,
    );
  }

  /// Create a new user.
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? branchId,
  }) async {
    state = const UsersLoading();

    final result = await _repository.create(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
      branchId: branchId,
    );

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (user) => UserOperationSuccess(
        message: 'User created successfully.',
        user: user,
      ),
    );
  }

  /// Deactivate a user account.
  Future<void> deactivateUser(String userId) async {
    final result = await _repository.deactivate(userId);

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (user) => UserOperationSuccess(
        message: 'User deactivated successfully.',
        user: user,
      ),
    );
  }

  /// Reactivate a deactivated user account.
  Future<void> reactivateUser(String userId) async {
    final result = await _repository.reactivate(userId);

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (user) => UserOperationSuccess(
        message: 'User reactivated successfully.',
        user: user,
      ),
    );
  }

  /// Reset a user's password.
  Future<void> resetPassword(String userId) async {
    final result = await _repository.resetPassword(userId);

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (_) => const UserOperationSuccess(
        message: 'Password reset email sent.',
      ),
    );
  }

  /// Force logout a user from all sessions.
  Future<void> forceLogout(String userId) async {
    final result = await _repository.forceLogout(userId);

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (_) => const UserOperationSuccess(
        message: 'User logged out from all sessions.',
      ),
    );
  }

  /// Update a user's role.
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    final result = await _repository.updateRole(
      userId: userId,
      newRole: newRole,
    );

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (user) => UserOperationSuccess(
        message: 'User role updated successfully.',
        user: user,
      ),
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const UserInitial();
  }
}
