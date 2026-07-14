// lib/features/collections/data/datasources/collection_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/features/collections/data/models/collection_model.dart';

class CollectionRemoteDataSource {
  final Dio _dio;

  CollectionRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<CollectionListResult> list({
    String? status,
    String? method,
    String? riderId,
    String? lenderId,
    String? date,
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
      if (lenderId != null && lenderId.isNotEmpty) {
        queryParams['lender_id'] = lenderId;
      }
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        ApiEndpoints.collections,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final collections = (data['collections'] as List<dynamic>)
          .map((json) =>
              CollectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? collections.length;

      return CollectionListResult(
        collections: collections,
        total: total,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CollectionModel> detail(String collectionId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.collectionsById
            .replaceAll('{id}', collectionId),
      );
      return CollectionModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CollectionModel> assignRider({
    required String collectionId,
    required String riderId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.collectionsAssign,
        data: {
          'collection_id': collectionId,
          'rider_id': riderId,
        },
      );
      return CollectionModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CollectionModel> markCollected({
    required String collectionId,
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
        ApiEndpoints.collectionsComplete
            .replaceAll('{id}', collectionId),
        data: data,
      );
      return CollectionModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CollectionModel> markPartial({
    required String collectionId,
    required double collectedAmount,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.collectionsPartial
            .replaceAll('{id}', collectionId),
        data: {
          'collected_amount': collectedAmount,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return CollectionModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CollectionModel> markFailed(
    String collectionId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.collectionsFail
            .replaceAll('{id}', collectionId),
        data: reason != null ? {'reason': reason} : null,
      );
      return CollectionModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CollectionListResult> getTodayCollections(
    String riderId,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.collectionsToday,
        queryParameters: {'rider_id': riderId},
      );

      final data = response.data as Map<String, dynamic>;
      final collections = (data['collections'] as List<dynamic>)
          .map((json) =>
              CollectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? collections.length;

      return CollectionListResult(
        collections: collections,
        total: total,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CollectionListResult> getByRider(
    String riderId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.collectionsByRider
            .replaceAll('{riderId}', riderId),
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final collections = (data['collections'] as List<dynamic>)
          .map((json) =>
              CollectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? collections.length;

      return CollectionListResult(
        collections: collections,
        total: total,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<RiderBrief>> getAvailableRiders() async {
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
              RiderBrief.fromJson(json as Map<String, dynamic>))
          .toList();
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
            message:
                'You do not have permission to manage collections.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Collection not found.',
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

class CollectionListResult {
  final List<CollectionModel> collections;
  final int total;

  const CollectionListResult({
    required this.collections,
    required this.total,
  });
}

class RiderBrief {
  final String id;
  final String name;
  final String? phone;
  final bool isAvailable;
  final int activeCollections;

  const RiderBrief({
    required this.id,
    required this.name,
    this.phone,
    this.isAvailable = true,
    this.activeCollections = 0,
  });

  factory RiderBrief.fromJson(Map<String, dynamic> json) {
    return RiderBrief(
      id: json['id'] as String,
      name: json['name'] as String? ??
          json['full_name'] as String? ??
          'Unknown Rider',
      phone: json['phone'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      activeCollections:
          json['active_collections'] as int? ?? 0,
    );
  }
}
