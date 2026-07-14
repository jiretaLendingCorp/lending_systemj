// lib/features/borrowers/data/datasources/borrower_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/features/borrowers/data/models/borrower_profile_model.dart';
import 'package:jireta_loan/features/loans/data/models/loan_model.dart';
import 'package:jireta_loan/features/payments/data/models/payment_model.dart';

class BorrowerRemoteDataSource {
  final Dio _dio;

  BorrowerRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<BorrowerProfileModel> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.usersMe);
      return BorrowerProfileModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<BorrowerProfileModel> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.usersMe,
        data: data,
      );
      return BorrowerProfileModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<LoanModel>> getOwnLoans({
    String? status,
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

      final response = await _dio.get(
        ApiEndpoints.loans,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((json) => LoanModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final loans = data['loans'] as List<dynamic>? ?? [];
      return loans
          .map((json) => LoanModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<PaymentModel>> getOwnPayments({
    String? loanId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (loanId != null) {
        queryParams['loan_id'] = loanId;
      }

      final response = await _dio.get(
        ApiEndpoints.payments,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final payments = data['payments'] as List<dynamic>? ?? [];
      return payments
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
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
            message: 'You do not have permission to access this resource.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Profile not found.',
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
