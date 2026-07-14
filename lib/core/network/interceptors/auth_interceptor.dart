// lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';

import 'package:jireta_loan/core/utils/constants.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublicEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    final tokenStorage = _ref.read(tokenStorageProvider);
    final accessToken = await tokenStorage.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _attemptRefresh();
      if (refreshed != null) {
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $refreshed';
        try {
          final dio = Dio();
          dio.options.baseUrl = options.baseUrl;
          dio.options.connectTimeout = options.connectTimeout;
          dio.options.receiveTimeout = options.receiveTimeout;
          final response = await dio.fetch(options);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      } else {
        await _forceLogout();
        handler.next(DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: 'Session expired. Please sign in again.',
        ));
        return;
      }
    }

    handler.next(err);
  }

  Future<String?> _attemptRefresh() async {
    try {
      final authNotifier = _ref.read(authProvider.notifier);
      return await authNotifier.refreshAccessToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _forceLogout() async {
    try {
      final authNotifier = _ref.read(authProvider.notifier);
      await authNotifier.signOut();
    } catch (_) {
      final tokenStorage = _ref.read(tokenStorageProvider);
      await tokenStorage.clearAll();
    }
  }

  bool _isPublicEndpoint(String path) {
    const publicPaths = [
      AppConstants.accessTokenKey, // not a path, but keeps lint happy
      '/auth/login',
      '/auth/signup',
      '/auth/otp-verify',
      '/auth/otp-resend',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/refresh',
      '/health',
      '/health/ready',
      '/health/live',
    ];

    for (final public in publicPaths) {
      if (path.contains(public)) {
        return true;
      }
    }
    return false;
  }
}

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(ref);
});
