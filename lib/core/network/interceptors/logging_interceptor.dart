import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Structured logging interceptor for debug builds only.
///
/// Logs request method, URL, headers, body, and response
/// status / data in a readable format. Stripped in release builds.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('══════════════════════════════════════════════════');
      debugPrint('[$timestamp] REQUEST → ${options.method} ${options.uri}');
      debugPrint('  Headers: ${_formatHeaders(options.headers)}');
      if (options.data != null) {
        debugPrint('  Body: ${_truncate(options.data.toString(), 500)}');
      }
      if (options.queryParameters.isNotEmpty) {
        debugPrint('  Query: ${options.queryParameters}');
      }
      debugPrint('══════════════════════════════════════════════════');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('══════════════════════════════════════════════════');
      debugPrint('[$timestamp] RESPONSE ← ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('  Headers: ${_formatHeaders(response.headers.map)}');
      if (response.data != null) {
        debugPrint('  Data: ${_truncate(response.data.toString(), 500)}');
      }
      debugPrint('══════════════════════════════════════════════════');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('══════════════════════════════════════════════════');
      debugPrint('[$timestamp] ERROR ← ${err.type} ${err.requestOptions.uri}');
      if (err.response != null) {
        debugPrint('  Status: ${err.response?.statusCode}');
        debugPrint('  Data: ${_truncate(err.response?.data?.toString() ?? 'N/A', 500)}');
      }
      debugPrint('  Message: ${err.message}');
      debugPrint('══════════════════════════════════════════════════');
    }
    handler.next(err);
  }

  /// Format headers map into a readable string.
  String _formatHeaders(dynamic headers) {
    if (headers is Map<String, dynamic>) {
      final sanitized = Map<String, dynamic>.from(headers);
      // Mask sensitive headers
      if (sanitized.containsKey('Authorization')) {
        sanitized['Authorization'] = 'Bearer ****';
      }
      return sanitized.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }
    if (headers is Map<String, List<String>>) {
      return headers.entries
          .map((e) => '${e.key}: ${e.value.join(', ')}')
          .join(', ');
    }
    return headers.toString();
  }

  /// Truncate long strings for readability.
  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}... [truncated]';
  }
}
