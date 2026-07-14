import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:lendflow/features/reports/data/repositories/report_repository_impl.dart';
import 'package:lendflow/features/reports/domain/entities/report_data.dart';
import 'package:lendflow/features/reports/domain/repositories/report_repository.dart';

// ─────────────────────────────────────────────────────────────────
// Report states
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level report state.
sealed class ReportFeatureState {
  const ReportFeatureState();
}

/// Initial state.
class ReportInitial extends ReportFeatureState {
  const ReportInitial();
}

/// Report is being loaded.
class ReportLoading extends ReportFeatureState {
  const ReportLoading();
}

/// Portfolio report loaded.
class PortfolioLoaded extends ReportFeatureState {
  final PortfolioReport report;

  const PortfolioLoaded({required this.report});
}

/// Overdue report loaded.
class OverdueLoaded extends ReportFeatureState {
  final OverdueReport report;

  const OverdueLoaded({required this.report});
}

/// Collection efficiency report loaded.
class CollectionEfficiencyLoaded extends ReportFeatureState {
  final CollectionEfficiencyReport report;

  const CollectionEfficiencyLoaded({required this.report});
}

/// Report export succeeded.
class ReportExportSuccess extends ReportFeatureState {
  final String downloadUrl;

  const ReportExportSuccess({required this.downloadUrl});
}

/// An error occurred.
class ReportError extends ReportFeatureState {
  final String message;
  final Failure? failure;

  const ReportError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [ReportRemoteDataSource].
final reportRemoteDataSourceProvider =
    Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [ReportRepository] implementation.
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(
    remoteDataSource: ref.watch(reportRemoteDataSourceProvider),
  );
});

/// Provides the [ReportNotifier] for report screens.
final reportFeatureProvider =
    StateNotifierProvider<ReportNotifier, ReportFeatureState>((ref) {
  return ReportNotifier(
    repository: ref.watch(reportRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// Report notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing report UI state.
class ReportNotifier extends StateNotifier<ReportFeatureState> {
  final ReportRepository _repository;

  ReportNotifier({
    required ReportRepository repository,
  })  : _repository = repository,
        super(const ReportInitial());

  /// Load the portfolio report.
  Future<void> loadPortfolio({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const ReportLoading();

    final result = await _repository.getPortfolio(
      startDate: startDate,
      endDate: endDate,
    );

    state = result.fold(
      (failure) => ReportError(failure.message, failure: failure),
      (report) => PortfolioLoaded(report: report),
    );
  }

  /// Load the overdue report.
  Future<void> loadOverdue({DateTime? asOfDate}) async {
    state = const ReportLoading();

    final result = await _repository.getOverdue(asOfDate: asOfDate);

    state = result.fold(
      (failure) => ReportError(failure.message, failure: failure),
      (report) => OverdueLoaded(report: report),
    );
  }

  /// Load the collection efficiency report.
  Future<void> loadCollectionEfficiency({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const ReportLoading();

    final result = await _repository.getCollectionEfficiency(
      startDate: startDate,
      endDate: endDate,
    );

    state = result.fold(
      (failure) => ReportError(failure.message, failure: failure),
      (report) => CollectionEfficiencyLoaded(report: report),
    );
  }

  /// Export a report.
  Future<void> exportReport({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await _repository.exportReport(
      reportType: reportType,
      format: format,
      startDate: startDate,
      endDate: endDate,
    );

    state = result.fold(
      (failure) => ReportError(failure.message, failure: failure),
      (url) => ReportExportSuccess(downloadUrl: url),
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const ReportInitial();
  }
}
