import 'package:dio/dio.dart';
import 'package:lendflow/core/error/error_handler.dart';
import 'package:lendflow/core/error/failures.dart';

/// Interceptor that maps HTTP error responses to typed [Failure] objects.
///
/// This interceptor catches [DioException]s and converts them into
/// structured [Failure] subtypes via [ErrorHandler], then re-throws
/// them as [DioException]s with the [Failure] attached in the `error`
/// field for easy downstream access.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convert DioException to a Failure via ErrorHandler
    final failure = ErrorHandler.handleDioError(err);

    // Create a new DioException with the Failure attached
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
