// lib/features/riders/data/datasources/rider_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/features/riders/data/models/rider_task_model.dart';

class RiderRemoteDataSource {
  final Dio _dio;

  RiderRemoteDataSource({required Dio dio}) : _dio = dio;

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
        },
      );
      return RiderTaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

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

  String _currentRiderId() => 'me';

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
