import 'dart:math';

import 'package:dio/dio.dart';

/// Interceptor that adds a UUID v4 `Idempotency-Key` header to all
/// POST requests, ensuring safe retries without duplicate side-effects.
///
/// The key is generated per request and is not reused across retries
/// of the same logical request (the retry interceptor handles that
/// separately). If a caller provides their own `Idempotency-Key`,
/// it is preserved.
class IdempotencyInterceptor extends Interceptor {
  final Random _random = Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'POST') {
      // Only add a key if the caller hasn't provided one
      options.headers.putIfAbsent('Idempotency-Key', () => _generateUuidV4());
    }
    handler.next(options);
  }

  /// Generate a UUID v4 string (RFC 4122 compliant).
  ///
  /// Uses [Random] to generate the 128 bits, then sets the
  /// version (4) and variant (10xx) bits as required.
  String _generateUuidV4() {
    // Generate 16 random bytes
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version to 4 (random UUID) — high nibble of byte 6
    bytes[6] = (bytes[6] & 0x0F) | 0x40;

    // Set variant to RFC 4122 — high 2 bits of byte 8 = 10
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    // Format as 8-4-4-4-12 hex string
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
