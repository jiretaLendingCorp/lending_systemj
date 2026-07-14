import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/riders/data/models/rider_task_model.dart';

/// Remote data source for rider task operations using Dio.
///
/// Provides methods for fetching today's tasks, GPS check-in,
/// marking tasks as delivered or collected, and retrieving history.
class RiderRemoteDataSource {
  final Dio _dio;

  RiderRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Fetch today's assigned tasks for the authenticated rider.
  ///
  /// Returns a list of [RiderTaskModel]s for the current date.
  Future<List<RiderTaskModel>> getTodayTasks({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _dio.get(
        ApiEndpoints.ridersTodayRoute.replaceAll('{id}', _currentRiderId()),
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((json) =>
                RiderTaskModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final tasks = data['tasks'] as List<dynamic>? ?? [];
      return tasks
          .map((json) =>
              RiderTaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Perform GPS check-in for a task.
  ///
  /// Sends the rider's current GPS coordinates along with the task ID.
  /// The server validates that the rider is within the allowed radius
  /// of the borrower's address.
  Future<RiderTaskModel> gpsCheckin({
    required String taskId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.riders}/tasks/$taskId/gps-checkin',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'checked_in_at': DateTime.now().toIso8601String(),
        },
      );
      return RiderTaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark a disbursement task as delivered.
  ///
  /// Called after the rider has successfully delivered cash to the borrower.
  /// An optional [photoReceiptUrl] can be provided as proof of delivery.
  Future<RiderTaskModel> markDelivered({
    required String taskId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'delivered_at': DateTime.now().toIso8601String(),
      };
      if (photoReceiptUrl != null) {
        data['photo_receipt_url'] = photoReceiptUrl;
      }

      final response = await _dio.post(
        '${ApiEndpoints.riders}/tasks/$taskId/deliver',
        data: data,
      );
      return RiderTaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark a collection task as collected.
  ///
  /// Called after the rider has successfully collected payment from
  /// the borrower. The [amount] collected and GPS coordinates are required.
  Future<RiderTaskModel> markCollected({
    required String taskId,
    required double amount,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'amount': amount,
        'latitude': latitude,
        'longitude': longitude,
        'collected_at': DateTime.now().toIso8601String(),
      };
      if (photoReceiptUrl != null) {
        data['photo_receipt_url'] = photoReceiptUrl;
      }

      final response = await _dio.post(
        '${ApiEndpoints.riders}/tasks/$taskId/collect',
        data: data,
      );
      return RiderTaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetch the rider's task history with optional date range.
  ///
  /// Returns completed and failed tasks for the given period.
  Future<List<RiderTaskModel>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'status': 'completed,failed',
      };
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T').first;
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T').first;
      }

      final response = await _dio.get(
        ApiEndpoints.ridersAssignments.replaceAll('{id}', _currentRiderId()),
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((json) =>
                RiderTaskModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final tasks = data['tasks'] as List<dynamic>? ?? [];
      return tasks
          .map((json) =>
              RiderTaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Placeholder for getting the current rider's ID from auth context.
  ///
  /// In production, this is resolved from the auth token or a local cache.
  String _currentRiderId() => 'me';

  // ── Private helpers ─────────────────────────────────────────────

  /// Map a [DioException] to the appropriate [AppException] subtype.
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
            message: 'You do not have permission to access rider tasks.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Task not found.',
            statusCode: 404,
          );
        }
        if (statusCode == 400 || statusCode == 422) {
          final data = e.response?.data;
          final fieldErrors = <String, String>{};
          if (data is Map<String, dynamic>) {
            final errors = data['errors'] as Map<String, dynamic>?;
            if (errors != null) {
              errors.forEach((key, value) {
                fieldErrors[key] = value.toString();
              });
            }
          }
          return ValidationException(
            message: data?['message'] as String? ?? 'Validation error.',
            statusCode: statusCode,
            fieldErrors: fieldErrors,
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
