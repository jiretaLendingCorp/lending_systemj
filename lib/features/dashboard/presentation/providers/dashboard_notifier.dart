import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/core/utils/constants.dart';
import 'package:lendflow/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:lendflow/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:lendflow/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:lendflow/features/dashboard/domain/repositories/dashboard_repository.dart';

// ─────────────────────────────────────────────────────────────────
// Dashboard states
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level dashboard state.
sealed class DashboardFeatureState {
  const DashboardFeatureState();
}

/// Initial state.
class DashboardInitial extends DashboardFeatureState {
  const DashboardInitial();
}

/// Dashboard is loading.
class DashboardLoading extends DashboardFeatureState {
  const DashboardLoading();
}

/// Dashboard loaded successfully.
class DashboardLoaded extends DashboardFeatureState {
  final DashboardStats stats;
  final List<RecentActivity> recentActivity;

  const DashboardLoaded({
    required this.stats,
    this.recentActivity = const [],
  });
}

/// An error occurred.
class DashboardError extends DashboardFeatureState {
  final String message;
  final Failure? failure;

  const DashboardError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [DashboardRemoteDataSource].
final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [DashboardRepository] implementation.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: ref.watch(dashboardRemoteDataSourceProvider),
  );
});

/// Provides the [DashboardNotifier] for dashboard screens.
final dashboardFeatureProvider =
    StateNotifierProvider<DashboardNotifier, DashboardFeatureState>((ref) {
  return DashboardNotifier(
    repository: ref.watch(dashboardRepositoryProvider),
  );
});

/// Whether the current user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.role == AppConstants.roleAdmin;
  }
  return false;
});

// ─────────────────────────────────────────────────────────────────
// Dashboard notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing dashboard UI state.
class DashboardNotifier extends StateNotifier<DashboardFeatureState> {
  final DashboardRepository _repository;

  DashboardNotifier({
    required DashboardRepository repository,
  })  : _repository = repository,
        super(const DashboardInitial());

  /// Load admin dashboard stats.
  Future<void> loadAdminStats() async {
    state = const DashboardLoading();

    final result = await _repository.getAdminStats();

    state = result.fold(
      (failure) => DashboardError(failure.message, failure: failure),
      (data) => DashboardLoaded(
        stats: data.stats,
        recentActivity: data.recentActivity,
      ),
    );
  }

  /// Load manager dashboard stats (branch-scoped).
  Future<void> loadManagerStats() async {
    state = const DashboardLoading();

    final result = await _repository.getManagerStats();

    state = result.fold(
      (failure) => DashboardError(failure.message, failure: failure),
      (data) => DashboardLoaded(
        stats: data.stats,
        recentActivity: data.recentActivity,
      ),
    );
  }

  /// Refresh the dashboard (keeps current role context).
  Future<void> refresh({bool isAdmin = true}) async {
    if (isAdmin) {
      await loadAdminStats();
    } else {
      await loadManagerStats();
    }
  }

  /// Reset state to initial.
  void resetState() {
    state = const DashboardInitial();
  }
}
