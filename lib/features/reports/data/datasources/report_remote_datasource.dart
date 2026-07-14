import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/reports/data/models/report_models.dart';

/// Remote data source for report operations using Dio.
///
/// Provides endpoints for portfolio, overdue, and collection
/// efficiency reports with optional date range filtering.
class ReportRemoteDataSource {
  final Dio _dio;

  ReportRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Fetch the loan portfolio report.
  ///
  /// Optional [startDate] and [endDate] for filtering.
  Future<PortfolioReportModel> getPortfolio({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        ApiEndpoints.reportsLoanPortfolio,
        queryParameters: queryParams,
      );
      return PortfolioReportModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetch the overdue aging report.
  ///
  /// Groups overdue loans into 1-7 days, 8-30 days, and 30+ days buckets.
  Future<OverdueReportModel> getOverdue({
    DateTime? asOfDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (asOfDate != null) {
        queryParams['as_of_date'] = asOfDate.toIso8601String();
      }

      final response = await _dio.get(
        ApiEndpoints.reportsOverdue,
        queryParameters: queryParams,
      );
      return OverdueReportModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetch the collection efficiency report.
  ///
  /// Optional [startDate] and [endDate] for filtering.
  Future<CollectionEfficiencyReportModel> getCollectionEfficiency({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        ApiEndpoints.reportsCollectionEfficiency,
        queryParameters: queryParams,
      );
      return CollectionEfficiencyReportModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Export a report as CSV/PDF.
  ///
  /// Returns the download URL or binary data depending on the backend.
  Future<String> exportReport({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'report_type': reportType,
        'format': format,
      };
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        ApiEndpoints.reportsExport,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      return data['download_url'] as String? ?? '';
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
            message: 'You do not have permission to view reports.',
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
