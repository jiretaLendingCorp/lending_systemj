// lib/core/network/interceptors/idempotency_interceptor.dart
import 'dart:math';

import 'package:dio/dio.dart';

class IdempotencyInterceptor extends Interceptor {
  final Random _random = Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'POST') {
      options.headers.putIfAbsent('Idempotency-Key', () => _generateUuidV4());
    }
    handler.next(options);
  }

  String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0F) | 0x40;

    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
