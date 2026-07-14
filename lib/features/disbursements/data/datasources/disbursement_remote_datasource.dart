import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/disbursements/data/models/disbursement_model.dart';

/// Remote data source for disbursement operations using Dio.
///
/// All disbursement CRUD operations go through the backend API.
/// The Dio instance includes auth, idempotency, and error interceptors.
class DisbursementRemoteDataSource {
  final Dio _dio;

  DisbursementRemoteDataSource({required Dio dio}) : _dio = dio;

  /// List disbursements with optional filters and pagination.
  Future<DisbursementListResult> list({
    String? status,
    String? method,
    String? riderId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (method != null && method.isNotEmpty) {
        queryParams['method'] = method;
      }
      if (riderId != null && riderId.isNotEmpty) {
        queryParams['rider_id'] = riderId;
      }

      final response = await _dio.get(
        ApiEndpoints.loansDisburse.replaceAll('{id}', ''),
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final disbursements = (data['disbursements'] as List<dynamic>)
          .map((json) =>
              DisbursementModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? disbursements.length;

      return DisbursementListResult(
        disbursements: disbursements,
        total: total,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Get detailed information about a specific disbursement.
  Future<DisbursementModel> detail(String disbursementId) async {
    try {
      final response = await _dio.get(
        '/disbursements/$disbursementId',
      );
      return DisbursementModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Assign a rider to a disbursement (manager/admin).
  ///
  /// Transitions the disbursement from [pending] to [assigned].
  Future<DisbursementModel> assignRider({
    required String disbursementId,
    required String riderId,
  }) async {
    try {
      final response = await _dio.post(
        '/disbursements/$disbursementId/assign',
        data: {'rider_id': riderId},
      );
      return DisbursementModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark a disbursement as delivered (rider action).
  ///
  /// Requires GPS coordinates from the rider's device.
  /// Transitions the disbursement from [in_transit] to [delivered].
  Future<DisbursementModel> markDelivered({
    required String disbursementId,
    required double latitude,
    required double longitude,
    String? receiptPhotoUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (receiptPhotoUrl != null) {
        data['receipt_photo_url'] = receiptPhotoUrl;
      }

      final response = await _dio.post(
        '/disbursements/$disbursementId/deliver',
        data: data,
      );
      return DisbursementModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark a disbursement as in transit (rider starts delivery).
  Future<DisbursementModel> markInTransit(String disbursementId) async {
    try {
      final response = await _dio.post(
        '/disbursements/$disbursementId/in-transit',
      );
      return DisbursementModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark a disbursement as failed.
  Future<DisbursementModel> markFailed(
    String disbursementId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/disbursements/$disbursementId/fail',
        data: reason != null ? {'reason': reason} : null,
      );
      return DisbursementModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Get available riders for assignment.
  Future<List<RiderInfo>> getAvailableRiders() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.riders,
        queryParameters: {'available': true},
      );

      final data = response.data;
      final riders = (data is List)
          ? data
          : (data['riders'] as List<dynamic>? ?? []);

      return riders
          .map((json) =>
              RiderInfo.fromJson(json as Map<String, dynamic>))
          .toList();
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
            message:
                'You do not have permission to manage disbursements.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Disbursement not found.',
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
            message:
                data?['message'] as String? ?? 'Validation error.',
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

/// Paginated result for disbursement list queries.
class DisbursementListResult {
  final List<DisbursementModel> disbursements;
  final int total;

  const DisbursementListResult({
    required this.disbursements,
    required this.total,
  });
}

/// Simplified rider info for assignment dialog.
class RiderInfo {
  final String id;
  final String name;
  final String? phone;
  final bool isAvailable;
  final int activeDeliveries;

  const RiderInfo({
    required this.id,
    required this.name,
    this.phone,
    this.isAvailable = true,
    this.activeDeliveries = 0,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) {
    return RiderInfo(
      id: json['id'] as String,
      name: json['name'] as String? ??
          json['full_name'] as String? ??
          'Unknown Rider',
      phone: json['phone'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      activeDeliveries:
          json['active_deliveries'] as int? ?? 0,
    );
  }
}
