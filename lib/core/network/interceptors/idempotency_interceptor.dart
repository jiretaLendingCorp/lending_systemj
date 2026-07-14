// lib/core/network/interceptors/idempotency_interceptor.dart
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

class IdempotencyInterceptor extends Interceptor {
  final Random _random = Random.secure();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'POST') {
      final key = _generateUuidV4();
      options.headers.putIfAbsent('Idempotency-Key', () => key);
      options.headers.putIfAbsent('X-Idempotency-Key', () => key);
      _injectIntoBody(options, key);
    }
    handler.next(options);
  }

  void _injectIntoBody(RequestOptions options, String key) {
    final data = options.data;
    if (data is Map<String, dynamic>) {
      data.putIfAbsent('idempotency_key', () => key);
      options.data = data;
      return;
    }
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          decoded.putIfAbsent('idempotency_key', () => key);
          options.data = jsonEncode(decoded);
        }
      } catch (_) {
      }
    }
  }

  String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0F) | 0x40;

    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
