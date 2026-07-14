import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:lendflow/features/dashboard/domain/entities/dashboard_stats.dart';

/// Remote data source for dashboard operations using Dio.
///
/// Provides stats endpoints for admin (full system) and manager
/// (branch-scoped) dashboards.
class DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Fetch admin dashboard statistics (full system).
  Future<DashboardData> getAdminStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.dashboardAdmin);
      final data = response.data as Map<String, dynamic>;

      final stats = DashboardStatsModel.fromJson(data);
      final recentActivity = (data['recent_activity'] as List<dynamic>? ?? [])
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return DashboardData(stats: stats, recentActivity: recentActivity);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetch manager dashboard statistics (own branch only).
  Future<DashboardData> getManagerStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.dashboardManager);
      final data = response.data as Map<String, dynamic>;

      final stats = DashboardStatsModel.fromJson(data);
      final recentActivity = (data['recent_activity'] as List<dynamic>? ?? [])
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return DashboardData(stats: stats, recentActivity: recentActivity);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────

  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please try again.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection. Please check your network.',
          isConnectionRefused: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return const AuthException(
            message: 'Session expired. Please sign in again.',
            tokenExpired: true,
            requiresReAuth: true,
          );
        }
        if (statusCode == 403) {
          return const AuthException(
            message: 'You do not have permission to view dashboard.',
          );
        }
        return ServerException(
          message: 'Server error occurred. Please try again later.',
          statusCode: statusCode,
          responseBody: e.response?.data,
        );
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Certificate verification failed.',
        );
      case DioExceptionType.unknown:
        return NetworkException(
          message: e.message ?? 'An unexpected error occurred.',
        );
    }
  }
}

/// Combined dashboard data with stats and recent activity.
class DashboardData {
  final DashboardStats stats;
  final List<RecentActivity> recentActivity;

  const DashboardData({
    required this.stats,
    this.recentActivity = const [],
  });
}
