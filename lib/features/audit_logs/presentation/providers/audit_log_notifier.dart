import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/audit_logs/data/datasources/audit_log_remote_datasource.dart';
import 'package:lendflow/features/audit_logs/data/repositories/audit_log_repository_impl.dart';
import 'package:lendflow/features/audit_logs/domain/entities/audit_log.dart';
import 'package:lendflow/features/audit_logs/domain/repositories/audit_log_repository.dart'
    as domain;

// ─────────────────────────────────────────────────────────────────
// Audit log states
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level audit log state.
sealed class AuditLogFeatureState {
  const AuditLogFeatureState();
}

/// Initial state.
class AuditLogInitial extends AuditLogFeatureState {
  const AuditLogInitial();
}

/// Logs are being loaded.
class AuditLogsLoading extends AuditLogFeatureState {
  const AuditLogsLoading();
}

/// Logs loaded successfully.
class AuditLogsLoaded extends AuditLogFeatureState {
  final List<AuditLog> logs;
  final int total;
  final int currentPage;

  const AuditLogsLoaded({
    required this.logs,
    required this.total,
    this.currentPage = 1,
  });

  /// Whether there are more pages to load.
  bool get hasMore => logs.length < total;
}

/// Export succeeded.
class AuditLogExportSuccess extends AuditLogFeatureState {
  final String downloadUrl;

  const AuditLogExportSuccess({required this.downloadUrl});
}

/// An error occurred.
class AuditLogError extends AuditLogFeatureState {
  final String message;
  final Failure? failure;

  const AuditLogError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [AuditLogRemoteDataSource].
final auditLogRemoteDataSourceProvider =
    Provider<AuditLogRemoteDataSource>((ref) {
  return AuditLogRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [AuditLogRepository] implementation.
final auditLogRepositoryProvider = Provider<domain.AuditLogRepository>((ref) {
  return AuditLogRepositoryImpl(
    remoteDataSource: ref.watch(auditLogRemoteDataSourceProvider),
  );
});

/// Provides the [AuditLogNotifier] for audit log screens.
final auditLogFeatureProvider =
    StateNotifierProvider<AuditLogNotifier, AuditLogFeatureState>((ref) {
  return AuditLogNotifier(
    repository: ref.watch(auditLogRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// Audit log notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing audit log UI state.
class AuditLogNotifier extends StateNotifier<AuditLogFeatureState> {
  final domain.AuditLogRepository _repository;

  AuditLogNotifier({
    required domain.AuditLogRepository repository,
  })  : _repository = repository,
        super(const AuditLogInitial());

  /// Load audit logs with optional filters.
  Future<void> loadLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  }) async {
    if (page == 1) {
      state = const AuditLogsLoading();
    }

    final result = await _repository.list(
      userId: userId,
      action: action,
      startDate: startDate,
      endDate: endDate,
      page: page,
    );

    state = result.fold(
      (failure) => AuditLogError(failure.message, failure: failure),
      (logListResult) {
        final existingLogs = state is AuditLogsLoaded && page > 1
            ? (state as AuditLogsLoaded).logs
            : <AuditLog>[];
        return AuditLogsLoaded(
          logs: [...existingLogs, ...logListResult.logs],
          total: logListResult.total,
          currentPage: page,
        );
      },
    );
  }

  /// Load more logs (pagination).
  Future<void> loadMore({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (state is! AuditLogsLoaded) return;
    final current = state as AuditLogsLoaded;
    if (!current.hasMore) return;

    await loadLogs(
      userId: userId,
      action: action,
      startDate: startDate,
      endDate: endDate,
      page: current.currentPage + 1,
    );
  }

  /// Get a single audit log detail.
  Future<void> loadDetail(String logId) async {
    final result = await _repository.detail(logId);
    // Detail loading doesn't change the list state
    result.fold(
      (failure) => AuditLogError(failure.message, failure: failure),
      (_) => null,
    );
  }

  /// Export audit logs as CSV.
  Future<void> exportLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await _repository.export(
      userId: userId,
      action: action,
      startDate: startDate,
      endDate: endDate,
    );

    state = result.fold(
      (failure) => AuditLogError(failure.message, failure: failure),
      (url) => AuditLogExportSuccess(downloadUrl: url),
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const AuditLogInitial();
  }
}
