import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/error/failures.dart';

/// Maps [DioExceptionType]s and HTTP status codes to typed [Failure]s.
///
/// Every data-source call should go through [handleDioError] so the
/// repository layer always receives a predictable [Failure] subtype.
class ErrorHandler {
  ErrorHandler._();

  /// Convert a [DioException] into a domain [Failure].
  static Failure handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: 'Connection timed out. Please try again.',
          code: error.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'No internet connection. Please check your network.',
          code: error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return const UnexpectedFailure(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'Secure connection failed. Certificate is invalid.',
        );

      case DioExceptionType.unknown:
        if (error.error != null && error.error.toString().contains('SocketException')) {
          return const NetworkFailure(
            message: 'No internet connection. Please check your network.',
          );
        }
        return UnexpectedFailure(
          message: error.message ?? 'An unexpected error occurred.',
          code: error.response?.statusCode,
        );
    }
  }

  /// Map an [AppException] to a [Failure].
  static Failure handleAppException(AppException exception) {
    return switch (exception) {
      ServerException(:final message, :final statusCode) => ServerFailure(
          message: message,
          code: statusCode,
          statusCode: statusCode,
        ),
      NetworkException(:final message, :final statusCode) => NetworkFailure(
          message: message,
          code: statusCode,
        ),
      AuthException(:final message, :final statusCode, :final requiresReAuth) =>
        AuthFailure(
          message: message,
          code: statusCode,
          requiresReAuth: requiresReAuth,
        ),
      ValidationException(:final message, :final statusCode, :final fieldErrors) =>
        ValidationFailure(
          message: message,
          code: statusCode,
          fieldErrors: fieldErrors,
        ),
      CacheException(:final message, :final statusCode) => CacheFailure(
          message: message,
          code: statusCode,
        ),
    };
  }

  static Failure _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = _extractMessage(data);

    switch (statusCode) {
      case 400:
        final fieldErrors = _extractFieldErrors(data);
        return ValidationFailure(
          message: serverMessage ?? 'Invalid request. Please check your input.',
          code: statusCode,
          fieldErrors: fieldErrors,
        );
      case 401:
        return AuthFailure(
          message: serverMessage ?? 'Session expired. Please sign in again.',
          code: statusCode,
          requiresReAuth: true,
        );
      case 403:
        return AuthFailure(
          message: serverMessage ?? 'You do not have permission to access this resource.',
          code: statusCode,
          requiresReAuth: false,
        );
      case 404:
        return ServerFailure(
          message: serverMessage ?? 'The requested resource was not found.',
          code: statusCode,
          statusCode: statusCode,
        );
      case 422:
        final fieldErrors = _extractFieldErrors(data);
        return ValidationFailure(
          message: serverMessage ?? 'Validation failed. Please check your input.',
          code: statusCode,
          fieldErrors: fieldErrors,
        );
      case 429:
        return ServerFailure(
          message: serverMessage ?? 'Too many requests. Please wait and try again.',
          code: statusCode,
          statusCode: statusCode,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerFailure(
            message: serverMessage ?? 'Server error. Please try again later.',
            code: statusCode,
            statusCode: statusCode,
          );
        }
        return UnexpectedFailure(
          message: serverMessage ?? 'An unexpected error occurred.',
          code: statusCode,
        );
    }
  }

  /// Attempt to pull a human-readable message from the response body.
  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['msg'] as String?;
    }
    if (data is String) {
      return data;
    }
    return null;
  }

  /// Attempt to extract field-level validation errors from the response.
  static Map<String, String> _extractFieldErrors(dynamic data) {
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        return errors.map((k, v) => MapEntry(k, v.toString()));
      }
      if (errors is List) {
        final Map<String, String> mapped = {};
        for (final e in errors) {
          if (e is Map<String, dynamic>) {
            final field = e['field'] as String? ?? e['param'] as String?;
            final msg = e['message'] as String? ?? e['msg'] as String?;
            if (field != null && msg != null) {
              mapped[field] = msg;
            }
          }
        }
        return mapped;
      }
    }
    return {};
  }
}
