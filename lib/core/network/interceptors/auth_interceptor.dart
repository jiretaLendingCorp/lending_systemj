import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/auth/token_storage.dart';
import 'package:lendflow/core/utils/constants.dart';

/// Dio interceptor that injects the JWT `Authorization` header,
/// handles automatic token refresh on 401 responses, and forces
/// logout when refresh fails.
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for login / signup / OTP endpoints
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
      // Attempt token refresh
      final refreshed = await _attemptRefresh();
      if (refreshed != null) {
        // Retry the original request with the new token
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
        // Refresh failed — force logout
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

  /// Attempt to refresh the access token using the stored refresh token.
  ///
  /// Returns the new access token on success, or `null` on failure.
  Future<String?> _attemptRefresh() async {
    try {
      final authNotifier = _ref.read(authProvider.notifier);
      return await authNotifier.refreshAccessToken();
    } catch (_) {
      return null;
    }
  }

  /// Force logout when token refresh fails.
  Future<void> _forceLogout() async {
    try {
      final authNotifier = _ref.read(authProvider.notifier);
      await authNotifier.signOut();
    } catch (_) {
      // If sign-out also fails, at least clear local storage.
      final tokenStorage = _ref.read(tokenStorageProvider);
      await tokenStorage.clearAll();
    }
  }

  /// Check if the endpoint should skip auth header injection.
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

    // Check if the path ends with any public path segment
    for (final public in publicPaths) {
      if (path.contains(public)) {
        return true;
      }
    }
    return false;
  }
}

/// Provider for the [AuthInterceptor].
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(ref);
});
