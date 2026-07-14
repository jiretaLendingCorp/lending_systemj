// lib/core/network/interceptors/error_interceptor.dart
import 'package:dio/dio.dart';
import 'package:jireta_loan/core/error/error_handler.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = ErrorHandler.handleDioError(err);

    final enrichedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: failure,
      message: failure.message,
    );

    handler.next(enrichedError);
  }
}
