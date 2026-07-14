import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:lendflow/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lendflow/features/notifications/domain/entities/app_notification.dart';
import 'package:lendflow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────
// Notification state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level notification state managed by [NotificationNotifier].
sealed class NotificationFeatureState {
  const NotificationFeatureState();
}

/// Initial state.
class NotificationInitial extends NotificationFeatureState {
  const NotificationInitial();
}

/// Loading state.
class NotificationLoading extends NotificationFeatureState {
  const NotificationLoading();
}

/// Notifications loaded successfully.
class NotificationsLoaded extends NotificationFeatureState {
  final List<AppNotification> notifications;
  final String? activeFilter;
  final int page;
  final bool hasMore;

  const NotificationsLoaded({
    required this.notifications,
    this.activeFilter,
    this.page = 1,
    this.hasMore = false,
  });

  /// Number of unread notifications.
  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  /// Whether there are any unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Notifications filtered by a specific type.
  List<AppNotification> filteredByType(NotificationType type) =>
      notifications.where((n) => n.type == type).toList();
}

/// An error occurred.
class NotificationError extends NotificationFeatureState {
  final String message;
  final Failure? failure;

  const NotificationError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [SupabaseClient] instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the [NotificationRemoteDataSource].
final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(
    dio: ref.watch(dioProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

/// Provides the [NotificationRepository] implementation.
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
  );
});

/// Provides the [NotificationNotifier] for notification feature screens.
final notificationFeatureProvider = StateNotifierProvider<
    NotificationNotifier, NotificationFeatureState>((ref) {
  return NotificationNotifier(
    repository: ref.watch(notificationRepositoryProvider),
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
    authProvider: ref.watch(authProvider),
  );
});

/// Provider for the unread notification count (for badges).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationFeatureProvider);
  if (state is NotificationsLoaded) {
    return state.unreadCount;
  }
  return 0;
});

// ─────────────────────────────────────────────────────────────────
// Notification notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing notification feature UI state.
///
/// Includes Supabase realtime subscription support for receiving
/// new notifications in real-time.
class NotificationNotifier extends StateNotifier<NotificationFeatureState> {
  final NotificationRepository _repository;
  final NotificationRemoteDataSource _remoteDataSource;
  final AuthState _authState;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription? _realtimeSubscription;

  NotificationNotifier({
    required NotificationRepository repository,
    required NotificationRemoteDataSource remoteDataSource,
    required AuthState authProvider,
  })  : _repository = repository,
        _remoteDataSource = remoteDataSource,
        _authState = authProvider,
        super(const NotificationInitial()) {
    _initRealtimeSubscription();
  }

  /// Initialize the Supabase realtime subscription for the current user.
  void _initRealtimeSubscription() {
    final userId = _currentUserId;
    if (userId == null) return;

    _realtimeChannel = _remoteDataSource.subscribeToRealtime(
      userId: userId,
      onNewNotification: (notification) {
        // Add the new notification to the current list
        if (state is NotificationsLoaded) {
          final current = state as NotificationsLoaded;
          state = NotificationsLoaded(
            notifications: [notification, ...current.notifications],
            activeFilter: current.activeFilter,
            page: current.page,
            hasMore: current.hasMore,
          );
        }
      },
    );

    _realtimeChannel?.subscribe();
  }

  /// Get the current user's ID from the auth state.
  String? get _currentUserId {
    if (_authState is AuthAuthenticated) {
      return (_authState as AuthAuthenticated).user.id;
    }
    return null;
  }

  /// Load notifications with optional type filter.
  Future<void> loadNotifications({
    String? type,
    int page = 1,
  }) async {
    if (page == 1) {
      state = const NotificationLoading();
    }

    final result = await _repository.list(
      type: type,
      page: page,
    );

    state = result.fold(
      (failure) => NotificationError(failure.message, failure: failure),
      (notifications) {
        final existingNotifications =
            state is NotificationsLoaded && page > 1
                ? (state as NotificationsLoaded).notifications
                : <AppNotification>[];
        return NotificationsLoaded(
          notifications: [
            ...existingNotifications,
            ...notifications,
          ],
          activeFilter: type,
          page: page,
          hasMore: notifications.length >= 20,
        );
      },
    );
  }

  /// Mark a specific notification as read.
  Future<void> markRead(String notificationId) async {
    final result = await _repository.markRead(notificationId);

    result.fold(
      (failure) {
        // Non-fatal: just log the error
      },
      (updatedNotification) {
        if (state is NotificationsLoaded) {
          final current = state as NotificationsLoaded;
          final updatedList = current.notifications
              .map((n) => n.id == notificationId ? updatedNotification : n)
              .toList();
          state = NotificationsLoaded(
            notifications: updatedList,
            activeFilter: current.activeFilter,
            page: current.page,
            hasMore: current.hasMore,
          );
        }
      },
    );
  }

  /// Mark all notifications as read.
  Future<void> markAllRead() async {
    final result = await _repository.markAllRead();

    result.fold(
      (failure) {
        // Non-fatal: just log the error
      },
      (_) {
        if (state is NotificationsLoaded) {
          final current = state as NotificationsLoaded;
          final updatedList = current.notifications
              .map((n) => n.isRead ? n : _markAsRead(n))
              .toList();
          state = NotificationsLoaded(
            notifications: updatedList,
            activeFilter: current.activeFilter,
            page: current.page,
            hasMore: current.hasMore,
          );
        }
      },
    );
  }

  /// Create a copy of the notification marked as read.
  AppNotification _markAsRead(AppNotification notification) {
    return AppNotification(
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      isRead: true,
      createdAt: notification.createdAt,
    );
  }

  /// Load more notifications (pagination).
  Future<void> loadMore({String? type}) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;
    if (!current.hasMore) return;

    await loadNotifications(
      type: type ?? current.activeFilter,
      page: current.page + 1,
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const NotificationInitial();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    final userId = _currentUserId;
    if (userId != null) {
      _remoteDataSource.unsubscribeFromRealtime(userId);
    }
    super.dispose();
  }
}
