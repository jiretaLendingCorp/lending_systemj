// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

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

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });

  @override
  List<Object?> get props => [message, code];
}

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

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });

  @override
  List<Object?> get props => [message, code];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.code,
  });

  @override
  List<Object?> get props => [message, code];
}
