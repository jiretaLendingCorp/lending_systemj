import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/notifications/data/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for notification operations using Dio and Supabase realtime.
///
/// Uses Dio for REST API calls (list, mark read, mark all read)
/// and Supabase realtime for push notification subscriptions.
class NotificationRemoteDataSource {
  final Dio _dio;
  final SupabaseClient _supabaseClient;

  NotificationRemoteDataSource({
    required Dio dio,
    required SupabaseClient supabaseClient,
  })  : _dio = dio,
        _supabaseClient = supabaseClient;

  /// List notifications with optional type filter and pagination.
  Future<List<NotificationModel>> list({
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((json) =>
                NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final notifications =
          data['notifications'] as List<dynamic>? ?? [];
      return notifications
          .map((json) =>
              NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark a specific notification as read.
  Future<NotificationModel> markRead(String notificationId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.notificationsMarkRead
            .replaceAll('{id}', notificationId),
      );
      return NotificationModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark all notifications as read for the authenticated user.
  Future<void> markAllRead() async {
    try {
      await _dio.post(ApiEndpoints.notificationsMarkAllRead);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Subscribe to realtime notification updates via Supabase.
  ///
  /// Returns a [RealtimeChannel] that the caller is responsible for
  /// subscribing and unsubscribing. The [onNewNotification] callback
  /// is invoked whenever a new notification is inserted.
  RealtimeChannel subscribeToRealtime({
    required String userId,
    required void Function(NotificationModel) onNewNotification,
  }) {
    return _supabaseClient
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (PostgresChangePayload payload) {
            final notification =
                NotificationModel.fromJson(payload.newRecord);
            onNewNotification(notification);
          },
        );
  }

  /// Unsubscribe from the realtime notification channel.
  Future<void> unsubscribeFromRealtime(String userId) async {
    await _supabaseClient
        .channel('notifications:$userId')
        .unsubscribe();
  }

  // ── Private helpers ─────────────────────────────────────────────

  /// Map a [DioException] to the appropriate [AppException] subtype.
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
        if (statusCode == 404) {
          return const ServerException(
            message: 'Notification not found.',
            statusCode: 404,
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
