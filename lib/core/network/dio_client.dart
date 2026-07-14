import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/core/network/interceptors/auth_interceptor.dart';
import 'package:lendflow/core/network/interceptors/error_interceptor.dart';
import 'package:lendflow/core/network/interceptors/idempotency_interceptor.dart';
import 'package:lendflow/core/network/interceptors/logging_interceptor.dart';
import 'package:lendflow/core/network/interceptors/retry_interceptor.dart';

/// Provider that creates and configures the singleton [Dio] instance.
///
/// All five interceptors are added in the correct execution order:
/// 1. [IdempotencyInterceptor] — adds Idempotency-Key to POSTs
/// 2. [AuthInterceptor] — injects JWT, handles 401 refresh
/// 3. [LoggingInterceptor] — structured debug logging
/// 4. [RetryInterceptor] — exponential backoff for 5xx
/// 5. [ErrorInterceptor] — maps HTTP errors to domain Failures
final dioProvider = Provider<Dio>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );

  // Add interceptors in the correct order.
  // Dio processes onRequest top→bottom, onResponse bottom→top,
  // onError bottom→top.
  dio.interceptors.addAll([
    const IdempotencyInterceptor(),
    authInterceptor,
    const LoggingInterceptor(),
    const RetryInterceptor(),
    const ErrorInterceptor(),
  ]);

  return dio;
});
