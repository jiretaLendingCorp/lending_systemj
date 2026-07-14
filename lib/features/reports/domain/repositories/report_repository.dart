// lib/features/reports/domain/repositories/report_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/reports/domain/entities/report_data.dart';

abstract class ReportRepository {
  Future<Either<Failure, PortfolioReport>> getPortfolio({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, OverdueReport>> getOverdue({
    DateTime? asOfDate,
  });

  Future<Either<Failure, CollectionEfficiencyReport>> getCollectionEfficiency({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, String>> exportReport({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  });
}
