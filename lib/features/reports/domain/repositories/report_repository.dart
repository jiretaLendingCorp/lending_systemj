import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/reports/domain/entities/report_data.dart';

/// Abstract repository for report operations.
abstract class ReportRepository {
  /// Fetch the loan portfolio report.
  Future<Either<Failure, PortfolioReport>> getPortfolio({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Fetch the overdue aging report.
  Future<Either<Failure, OverdueReport>> getOverdue({
    DateTime? asOfDate,
  });

  /// Fetch the collection efficiency report.
  Future<Either<Failure, CollectionEfficiencyReport>> getCollectionEfficiency({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Export a report as CSV/PDF.
  Future<Either<Failure, String>> exportReport({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  });
}
