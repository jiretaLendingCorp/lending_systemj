import 'package:equatable/equatable.dart';

/// Base failure type for domain-layer error representation.
///
/// All failures are immutable and value-comparable via [Equatable].
/// Feature layers return [Failure] subtypes from use-cases instead of
/// throwing, keeping the domain layer free of framework dependencies.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Represents a server-side error (5xx or unexpected response shape).
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Represents a network connectivity error (no internet, timeout, DNS failure).
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Represents an authentication / authorisation error (401, 403, token expiry).
class AuthFailure extends Failure {
  final bool requiresReAuth;

  const AuthFailure({
    required super.message,
    super.code,
    this.requiresReAuth = false,
  });

  @override
  List<Object?> get props => [message, code, requiresReAuth];
}

/// Represents a validation error (400, 422) with optional field-level details.
class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    this.fieldErrors = const {},
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Represents a local cache / storage error.
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Represents an unknown / unexpected error.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.code,
  });

  @override
  List<Object?> get props => [message, code];
}
