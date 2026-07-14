// lib/features/reports/presentation/providers/report_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:jireta_loan/features/reports/data/repositories/report_repository_impl.dart';
import 'package:jireta_loan/features/reports/domain/entities/report_data.dart';
import 'package:jireta_loan/features/reports/domain/repositories/report_repository.dart';


sealed class ReportFeatureState {
  const ReportFeatureState();
}

class ReportInitial extends ReportFeatureState {
  const ReportInitial();
}

class ReportLoading extends ReportFeatureState {
  const ReportLoading();
}

class PortfolioLoaded extends ReportFeatureState {
  final PortfolioReport report;

  const PortfolioLoaded({required this.report});
}

class OverdueLoaded extends ReportFeatureState {
  final OverdueReport report;

  const OverdueLoaded({required this.report});
}

class CollectionEfficiencyLoaded extends ReportFeatureState {
  final CollectionEfficiencyReport report;

  const CollectionEfficiencyLoaded({required this.report});
}

class ReportExportSuccess extends ReportFeatureState {
  final String downloadUrl;

  const ReportExportSuccess({required this.downloadUrl});
}

class ReportError extends ReportFeatureState {
  final String message;
  final Failure? failure;

  const ReportError(this.message, {this.failure});
}


final reportRemoteDataSourceProvider =
    Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSource(dio: ref.watch(dioProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(
    remoteDataSource: ref.watch(reportRemoteDataSourceProvider),
  );
});

final reportFeatureProvider =
    StateNotifierProvider<ReportNotifier, ReportFeatureState>((ref) {
  return ReportNotifier(
    repository: ref.watch(reportRepositoryProvider),
  );
});


class ReportNotifier extends StateNotifier<ReportFeatureState> {
  final ReportRepository _repository;

  ReportNotifier({
    required ReportRepository repository,
  })  : _repository = repository,
        super(const ReportInitial());

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

  Future<void> loadOverdue({DateTime? asOfDate}) async {
    state = const ReportLoading();

    final result = await _repository.getOverdue(asOfDate: asOfDate);

    state = result.fold(
      (failure) => ReportError(failure.message, failure: failure),
      (report) => OverdueLoaded(report: report),
    );
  }

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

  void resetState() {
    state = const ReportInitial();
  }
}
