import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/settings/data/models/system_settings_model.dart';

/// Remote data source for system settings operations using Dio.
///
/// Provides get and update operations for system settings.
/// Sensitive changes (interest rate, penalty rate) require
/// forced re-authentication via a separate re-auth endpoint.
class SettingsRemoteDataSource {
  final Dio _dio;

  SettingsRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Fetch the current system settings.
  Future<SystemSettingsModel> get() async {
    try {
      final response = await _dio.get(ApiEndpoints.settings);
      final data = response.data;

      // Handle both single object and nested response
      if (data is List && data.isNotEmpty) {
        return SystemSettingsModel.fromJson(
          data.first as Map<String, dynamic>,
        );
      }
      return SystemSettingsModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Update system settings.
  ///
  /// The [reAuthToken] is required for sensitive changes like
  /// interest rate or penalty rate modifications. The server
  /// validates this token against a recent authentication.
  Future<SystemSettingsModel> update({
    required Map<String, dynamic> data,
    String? reAuthToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (reAuthToken != null) {
        headers['X-Reauth-Token'] = reAuthToken;
      }

      final response = await _dio.patch(
        ApiEndpoints.settings,
        data: data,
        options: Options(headers: headers),
      );
      return SystemSettingsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Update interest rate (requires re-authentication).
  ///
  /// Calls the dedicated interest rate endpoint with re-auth verification.
  Future<SystemSettingsModel> updateInterestRate({
    required double interestRate,
    required String reAuthToken,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.settingsInterestRates,
        data: {'interest_rate': interestRate},
        options: Options(headers: {'X-Reauth-Token': reAuthToken}),
      );
      return SystemSettingsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Update penalty rate (requires re-authentication).
  Future<SystemSettingsModel> updatePenaltyRate({
    required double penaltyRate,
    required int penaltyThresholdDays,
    required String reAuthToken,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.settingsPenaltyRates,
        data: {
          'penalty_rate': penaltyRate,
          'penalty_threshold_days': penaltyThresholdDays,
        },
        options: Options(headers: {'X-Reauth-Token': reAuthToken}),
      );
      return SystemSettingsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Update SMS template (no re-auth required).
  Future<SystemSettingsModel> updateSmsTemplate({
    required String smsTemplate,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.settings,
        data: {'sms_template': smsTemplate},
      );
      return SystemSettingsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Update notification preferences (no re-auth required).
  Future<SystemSettingsModel> updateNotificationPreferences({
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.settingsNotifications,
        data: preferences,
      );
      return SystemSettingsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Update system flags (requires re-auth for maintenance mode).
  Future<SystemSettingsModel> updateSystemFlags({
    required Map<String, dynamic> flags,
    String? reAuthToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (reAuthToken != null) {
        headers['X-Reauth-Token'] = reAuthToken;
      }

      final response = await _dio.patch(
        ApiEndpoints.settingsSystem,
        data: flags,
        options: Options(headers: headers),
      );
      return SystemSettingsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────

  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please try again.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection. Please check your network.',
          isConnectionRefused: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return const AuthException(
            message: 'Session expired. Please sign in again.',
            tokenExpired: true,
            requiresReAuth: true,
          );
        }
        if (statusCode == 403) {
          return const AuthException(
            message: 'Re-authentication required for this action.',
            requiresReAuth: true,
          );
        }
        if (statusCode == 400 || statusCode == 422) {
          final data = e.response?.data;
          final fieldErrors = <String, String>{};
          if (data is Map<String, dynamic>) {
            final errors = data['errors'] as Map<String, dynamic>?;
            if (errors != null) {
              errors.forEach((key, value) {
                fieldErrors[key] = value.toString();
              });
            }
          }
          return ValidationException(
            message: data?['message'] as String? ?? 'Validation error.',
            statusCode: statusCode,
            fieldErrors: fieldErrors,
          );
        }
        return ServerException(
          message: 'Server error occurred. Please try again later.',
          statusCode: statusCode,
          responseBody: e.response?.data,
        );
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Certificate verification failed.',
        );
      case DioExceptionType.unknown:
        return NetworkException(
          message: e.message ?? 'An unexpected error occurred.',
        );
    }
  }
}
