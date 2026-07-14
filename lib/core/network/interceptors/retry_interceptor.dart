// lib/core/network/interceptors/retry_interceptor.dart
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:jireta_loan/core/utils/constants.dart';

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
          handler.next(retryError);
          return;
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    return false;
  }

  Duration _calculateDelay(int retryCount) {
    final exponentialDelay = initialDelay * pow(2, retryCount);
    final jitter = Duration(milliseconds: _random.nextInt(500));
    final totalDelay = exponentialDelay + jitter;
    return totalDelay > maxDelay ? maxDelay : totalDelay;
  }
}
