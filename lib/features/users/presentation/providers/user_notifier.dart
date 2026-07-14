// lib/features/users/presentation/providers/user_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/users/data/datasources/user_remote_datasource.dart';
import 'package:jireta_loan/features/users/data/repositories/user_repository_impl.dart';
import 'package:jireta_loan/features/users/domain/entities/user_management.dart';
import 'package:jireta_loan/features/users/domain/repositories/user_repository.dart'
    as domain;

sealed class UserFeatureState {
  const UserFeatureState();
}

class UserInitial extends UserFeatureState {
  const UserInitial();
}

class UsersLoading extends UserFeatureState {
  const UsersLoading();
}

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

  bool get hasMore => users.length < total;
}

class UserOperationSuccess extends UserFeatureState {
  final String message;
  final UserManagement? user;

  const UserOperationSuccess({
    required this.message,
    this.user,
  });
}

class UserError extends UserFeatureState {
  final String message;
  final Failure? failure;

  const UserError(this.message, {this.failure});
}

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(dio: ref.watch(dioProvider));
});

final userRepositoryProvider = Provider<domain.UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.watch(userRemoteDataSourceProvider),
  );
});

final userFeatureProvider =
    StateNotifierProvider<UserNotifier, UserFeatureState>((ref) {
  return UserNotifier(
    repository: ref.watch(userRepositoryProvider),
  );
});

class UserNotifier extends StateNotifier<UserFeatureState> {
  final domain.UserRepository _repository;

  UserNotifier({
    required domain.UserRepository repository,
  })  : _repository = repository,
        super(const UserInitial());

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

  Future<void> resetPassword(String userId) async {
    final result = await _repository.resetPassword(userId);

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (_) => const UserOperationSuccess(
        message: 'Password reset email sent.',
      ),
    );
  }

  Future<void> forceLogout(String userId) async {
    final result = await _repository.forceLogout(userId);

    state = result.fold(
      (failure) => UserError(failure.message, failure: failure),
      (_) => const UserOperationSuccess(
        message: 'User logged out from all sessions.',
      ),
    );
  }

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

  void resetState() {
    state = const UserInitial();
  }
}
