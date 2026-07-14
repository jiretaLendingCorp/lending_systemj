// lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:jireta_loan/features/dashboard/domain/entities/dashboard_stats.dart';

class DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<DashboardData> getAdminStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.dashboardHeadManager);
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

  Future<DashboardData> getManagerStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.dashboardEmployee);
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
          return const AppAuthException(
            message: 'Session expired. Please sign in again.',
            tokenExpired: true,
            requiresReAuth: true,
          );
        }
        if (statusCode == 403) {
          return const AppAuthException(
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

class DashboardData {
  final DashboardStats stats;
  final List<RecentActivity> recentActivity;

  const DashboardData({
    required this.stats,
    this.recentActivity = const [],
  });
}
