// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jireta_loan/core/network/api_endpoints.dart';
import 'package:jireta_loan/core/network/interceptors/auth_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/error_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/idempotency_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/logging_interceptor.dart';
import 'package:jireta_loan/core/network/interceptors/retry_interceptor.dart';

final supabaseAnonKeyProvider = Provider<String>((ref) {
  try {
    final client = Supabase.instance.client;
    final authHeaders = client.auth.headers;
    final apikey = authHeaders['apikey'] ??
        authHeaders['Authorization'] ??
        '';
    if (apikey.startsWith('Bearer ')) {
      return apikey.substring(7);
    }
    return apikey;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('supabaseAnonKeyProvider error: $e\n$st');
    }
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxjZWx6cnZwcXdsYmVjY3J3cGtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwMjgyMTAsImV4cCI6MjA5OTYwNDIxMH0.kSBD9jB8CFy1Oo5nTwtIslp-112dEP6bo1XszOuiPUU',
    );
  }
});

final dioProvider = Provider<Dio>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  final anonKey = ref.watch(supabaseAnonKeyProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey': anonKey,
      },
      responseType: ResponseType.json,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
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
