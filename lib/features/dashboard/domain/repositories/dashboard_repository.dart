// lib/features/dashboard/domain/repositories/dashboard_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardData>> getAdminStats();

  Future<Either<Failure, DashboardData>> getManagerStats();
}

class DashboardData {
  final DashboardStats stats;
  final List<RecentActivity> recentActivity;

  const DashboardData({
    required this.stats,
    this.recentActivity = const [],
  });
}
