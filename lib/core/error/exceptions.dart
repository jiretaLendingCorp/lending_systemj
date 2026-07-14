// lib/core/error/exceptions.dart
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => '$runtimeType(message: $message, statusCode: $statusCode, errorCode: $errorCode)';
}

class ServerException extends AppException {
  final dynamic responseBody;

  const ServerException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.responseBody,
  });
}

class NetworkException extends AppException {
  final bool isTimeout;
  final bool isConnectionRefused;

  const NetworkException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.isTimeout = false,
    this.isConnectionRefused = false,
  });
}

class AppAuthException extends AppException {
  final bool tokenExpired;
  final bool requiresReAuth;

  const AppAuthException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.tokenExpired = false,
    this.requiresReAuth = false,
  });
}

class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.fieldErrors = const {},
  });
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}
