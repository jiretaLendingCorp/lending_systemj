import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/audit_logs/data/models/audit_log_model.dart';

/// Remote data source for audit log operations using Dio.
///
/// Audit logs are read-only (admin access only). Supports
/// filtering by userId, action, and date range.
class AuditLogRemoteDataSource {
  final Dio _dio;

  AuditLogRemoteDataSource({required Dio dio}) : _dio = dio;

  /// List audit logs with optional filters and pagination.
  Future<AuditLogListResult> list({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId;
      }
      if (action != null && action.isNotEmpty) {
        queryParams['action'] = action;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        ApiEndpoints.audit,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final logs = (data['logs'] as List<dynamic>)
          .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? logs.length;

      return AuditLogListResult(logs: logs, total: total);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Get a single audit log detail by ID.
  Future<AuditLogModel> detail(String logId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.auditLog}/$logId',
      );
      return AuditLogModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Export audit logs as CSV.
  Future<String> export({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;
      if (action != null) queryParams['action'] = action;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _dio.get(
        '${ApiEndpoints.audit}/export',
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
            message: 'You do not have permission to view audit logs.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Audit log not found.',
            statusCode: 404,
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

/// Paginated result for audit log list queries.
class AuditLogListResult {
  final List<AuditLogModel> logs;
  final int total;

  const AuditLogListResult({
    required this.logs,
    required this.total,
  });
}
