// lib/features/payments/data/datasources/payment_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/features/payments/data/models/payment_model.dart';

class PaymentRemoteDataSource {
  final Dio _dio;

  PaymentRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<PaymentModel> create({
    required String loanId,
    required double amount,
    required String method,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.paymentsRecord,
        data: {
          'loan_id': loanId,
          'amount': amount,
          'method': method,
        },
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<PaymentListResult> list({
    String? loanId,
    String? lenderId,
    String? status,
    String? method,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (loanId != null && loanId.isNotEmpty) {
        queryParams['loan_id'] = loanId;
      }
      if (lenderId != null && lenderId.isNotEmpty) {
        queryParams['lender_id'] = lenderId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (method != null && method.isNotEmpty) {
        queryParams['method'] = method;
      }

      final response = await _dio.get(
        ApiEndpoints.payments,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final payments = (data['payments'] as List<dynamic>)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? payments.length;

      return PaymentListResult(payments: payments, total: total);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<PaymentListResult> getByLoanId(
    String loanId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.paymentsByLoan.replaceAll('{loanId}', loanId),
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final payments = (data['payments'] as List<dynamic>)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? payments.length;

      return PaymentListResult(payments: payments, total: total);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<PaymentModel> detail(String paymentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.paymentsById.replaceAll('{id}', paymentId),
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<PaymentModel> verify(String paymentId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.paymentsVerify.replaceAll('{id}', paymentId),
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<PaymentModel> reject(String paymentId, {String? reason}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.paymentsReject.replaceAll('{id}', paymentId),
        data: reason != null ? {'reason': reason} : null,
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<String> getReceiptUrl(String paymentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.paymentsReceipt.replaceAll('{id}', paymentId),
      );
      final data = response.data as Map<String, dynamic>;
      return data['receipt_url'] as String? ?? '';
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
            message: 'You do not have permission to manage payments.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Payment not found.',
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

class PaymentListResult {
  final List<PaymentModel> payments;
  final int total;

  const PaymentListResult({
    required this.payments,
    required this.total,
  });
}
