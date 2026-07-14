// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/core/network/interceptors/auth_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/error_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/idempotency_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/logging_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/retry_interceptor.dart';

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

  dio.interceptors.addAll([
    IdempotencyInterceptor(),
    authInterceptor,
    LoggingInterceptor(),
    RetryInterceptor(),
    ErrorInterceptor(),
  ]);

  return dio;
});
