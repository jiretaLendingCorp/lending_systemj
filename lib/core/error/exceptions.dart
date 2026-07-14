/// Base exception type for infrastructure / data-layer errors.
///
/// These are thrown by data sources and caught by repositories,
/// which then map them to [Failure] subtypes for the domain layer.
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

/// Server-side error (5xx or malformed response).
class ServerException extends AppException {
  final dynamic responseBody;

  const ServerException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.responseBody,
  });
}

/// Network connectivity error (no internet, timeout, DNS failure).
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

/// Authentication / authorisation error (401, 403, token expired).
class AuthException extends AppException {
  final bool tokenExpired;
  final bool requiresReAuth;

  const AuthException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.tokenExpired = false,
    this.requiresReAuth = false,
  });
}

/// Validation error (400, 422) with optional field-level details.
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.fieldErrors = const {},
  });
}

/// Cache / local storage error.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}
