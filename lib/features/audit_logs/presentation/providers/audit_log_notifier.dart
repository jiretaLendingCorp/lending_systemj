// lib/features/audit_logs/presentation/providers/audit_log_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/audit_logs/data/datasources/audit_log_remote_datasource.dart';
import 'package:jireta_loan/features/audit_logs/data/repositories/audit_log_repository_impl.dart';
import 'package:jireta_loan/features/audit_logs/domain/entities/audit_log.dart';
import 'package:jireta_loan/features/audit_logs/domain/repositories/audit_log_repository.dart'
    as domain;

sealed class AuditLogFeatureState {
  const AuditLogFeatureState();
}

class AuditLogInitial extends AuditLogFeatureState {
  const AuditLogInitial();
}

class AuditLogsLoading extends AuditLogFeatureState {
  const AuditLogsLoading();
}

class AuditLogsLoaded extends AuditLogFeatureState {
  final List<AuditLog> logs;
  final int total;
  final int currentPage;

  const AuditLogsLoaded({
    required this.logs,
    required this.total,
    this.currentPage = 1,
  });

  bool get hasMore => logs.length < total;
}

class AuditLogExportSuccess extends AuditLogFeatureState {
  final String downloadUrl;

  const AuditLogExportSuccess({required this.downloadUrl});
}

class AuditLogError extends AuditLogFeatureState {
  final String message;
  final Failure? failure;

  const AuditLogError(this.message, {this.failure});
}

final auditLogRemoteDataSourceProvider =
    Provider<AuditLogRemoteDataSource>((ref) {
  return AuditLogRemoteDataSource(dio: ref.watch(dioProvider));
});

final auditLogRepositoryProvider = Provider<domain.AuditLogRepository>((ref) {
  return AuditLogRepositoryImpl(
    remoteDataSource: ref.watch(auditLogRemoteDataSourceProvider),
  );
});

final auditLogFeatureProvider =
    StateNotifierProvider<AuditLogNotifier, AuditLogFeatureState>((ref) {
  return AuditLogNotifier(
    repository: ref.watch(auditLogRepositoryProvider),
  );
});

class AuditLogNotifier extends StateNotifier<AuditLogFeatureState> {
  final domain.AuditLogRepository _repository;

  AuditLogNotifier({
    required domain.AuditLogRepository repository,
  })  : _repository = repository,
        super(const AuditLogInitial());

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

  Future<void> loadDetail(String logId) async {
    final result = await _repository.detail(logId);
    result.fold(
      (failure) => AuditLogError(failure.message, failure: failure),
      (_) => null,
    );
  }

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

  void resetState() {
    state = const AuditLogInitial();
  }
}
