// lib/features/dashboard/presentation/providers/dashboard_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:jireta_loan/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:jireta_loan/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:jireta_loan/features/dashboard/domain/repositories/dashboard_repository.dart';


sealed class DashboardFeatureState {
  const DashboardFeatureState();
}

class DashboardInitial extends DashboardFeatureState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardFeatureState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardFeatureState {
  final DashboardStats stats;
  final List<RecentActivity> recentActivity;

  const DashboardLoaded({
    required this.stats,
    this.recentActivity = const [],
  });
}

class DashboardError extends DashboardFeatureState {
  final String message;
  final Failure? failure;

  const DashboardError(this.message, {this.failure});
}


final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(dio: ref.watch(dioProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: ref.watch(dashboardRemoteDataSourceProvider),
  );
});

final dashboardFeatureProvider =
    StateNotifierProvider<DashboardNotifier, DashboardFeatureState>((ref) {
  return DashboardNotifier(
    repository: ref.watch(dashboardRepositoryProvider),
  );
});

final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AppAuthAuthenticated) {
    return authState.role == AppConstants.roleHeadManager;
  }
  return false;
});


class DashboardNotifier extends StateNotifier<DashboardFeatureState> {
  final DashboardRepository _repository;

  DashboardNotifier({
    required DashboardRepository repository,
  })  : _repository = repository,
        super(const DashboardInitial());

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

  Future<void> refresh({bool isHeadManager = true}) async {
    if (isHeadManager) {
      await loadAdminStats();
    } else {
      await loadManagerStats();
    }
  }

  void resetState() {
    state = const DashboardInitial();
  }
}
