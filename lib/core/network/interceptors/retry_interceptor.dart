import 'dart:math';

import 'package:dio/dio.dart';
import 'package:lendflow/core/utils/constants.dart';

/// Retry interceptor with exponential backoff for server errors (5xx).
///
/// Retries up to [maxRetries] times with exponential delay:
///   1st retry: ~1s, 2nd retry: ~2s
///
/// Only retries on 5xx server errors and connectivity timeouts.
/// Does NOT retry 4xx client errors or cancelled requests.
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final Random _random = Random();

  RetryInterceptor({
    this.maxRetries = AppConstants.maxRetryAttempts,
    this.initialDelay = AppConstants.initialRetryDelay,
    this.maxDelay = AppConstants.maxRetryDelay,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
      if (retryCount < maxRetries) {
        final delay = _calculateDelay(retryCount);
        await Future<void>.delayed(delay);

        final options = err.requestOptions;
        options.extra['retryCount'] = retryCount + 1;

        try {
          final dio = Dio(BaseOptions(
            baseUrl: options.baseUrl,
            connectTimeout: options.connectTimeout,
            receiveTimeout: options.receiveTimeout,
            headers: options.headers,
          ));
          final response = await dio.fetch(options);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          // If retry also failed, continue the error chain
          // which may trigger another retry
          handler.next(retryError);
          return;
        }
      }
    }

    // No more retries or non-retryable error
    handler.next(err);
  }

  /// Determine if the error is retryable.
  bool _shouldRetry(DioException err) {
    // Retry on connectivity / timeout issues
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    // Do NOT retry 4xx client errors, cancelled requests, etc.
    return false;
  }

  /// Calculate exponential backoff delay with jitter.
  ///
  /// Formula: `min(initialDelay * 2^retryCount + random_jitter, maxDelay)`
  Duration _calculateDelay(int retryCount) {
    final exponentialDelay = initialDelay * pow(2, retryCount);
    final jitter = Duration(milliseconds: _random.nextInt(500));
    final totalDelay = exponentialDelay + jitter;
    return totalDelay > maxDelay ? maxDelay : totalDelay;
  }
}
