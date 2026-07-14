import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/dashboard/domain/entities/dashboard_stats.dart';

/// Abstract repository for dashboard operations.
abstract class DashboardRepository {
  /// Fetch admin dashboard statistics (full system).
  Future<Either<Failure, DashboardData>> getAdminStats();

  /// Fetch manager dashboard statistics (own branch only).
  Future<Either<Failure, DashboardData>> getManagerStats();
}

/// Combined dashboard data with stats and recent activity at the domain level.
class DashboardData {
  final DashboardStats stats;
  final List<RecentActivity> recentActivity;

  const DashboardData({
    required this.stats,
    this.recentActivity = const [],
  });
}
