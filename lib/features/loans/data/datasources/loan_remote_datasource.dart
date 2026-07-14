// lib/features/loans/data/datasources/loan_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/features/loans/data/models/loan_model.dart';
import 'package:jireta_loan/features/loans/data/models/loan_schedule_model.dart';
import 'package:jireta_loan/features/loans/data/models/create_loan_request.dart';

class LoanRemoteDataSource {
  final Dio _dio;

  LoanRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<LoanListResult> list({
    String? status,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        ApiEndpoints.loans,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final loans = (data['loans'] as List<dynamic>)
          .map((json) => LoanModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? loans.length;

      return LoanListResult(loans: loans, total: total);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<LoanModel> create(CreateLoanRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.loansApply,
        data: request.toJson(),
      );
      return LoanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<LoanModel> detail(String loanId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.loansById.replaceAll('{id}', loanId),
      );
      return LoanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<LoanScheduleModel>> schedule(String loanId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.loansSchedule.replaceAll('{id}', loanId),
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((json) =>
                LoanScheduleModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      final scheduleList = data['schedule'] as List<dynamic>? ?? [];
      return scheduleList
          .map((json) =>
              LoanScheduleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<LoanModel> approve(String loanId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.loansApprove.replaceAll('{id}', loanId),
      );
      return LoanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<LoanModel> reject(String loanId, {String? reason}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.loansReject.replaceAll('{id}', loanId),
        data: reason != null ? {'reason': reason} : null,
      );
      return LoanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<LoanModel> computePenalty(String loanId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.loansById.replaceAll('{id}', loanId),
        queryParameters: {'compute_penalty': true},
      );
      return LoanModel.fromJson(response.data as Map<String, dynamic>);
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
            message: 'You do not have permission to manage loans.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Loan not found.',
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

class LoanListResult {
  final List<LoanModel> loans;
  final int total;

  const LoanListResult({
    required this.loans,
    required this.total,
  });
}
