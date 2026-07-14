// lib/features/notifications/presentation/providers/notification_notifier.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:jireta_loan/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:jireta_loan/features/notifications/domain/entities/app_notification.dart';
import 'package:jireta_loan/features/notifications/domain/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


sealed class NotificationFeatureState {
  const NotificationFeatureState();
}

class NotificationInitial extends NotificationFeatureState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationFeatureState {
  const NotificationLoading();
}

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

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  List<AppNotification> filteredByType(NotificationType type) =>
      notifications.where((n) => n.type == type).toList();
}

class NotificationError extends NotificationFeatureState {
  final String message;
  final Failure? failure;

  const NotificationError(this.message, {this.failure});
}


final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(
    dio: ref.watch(dioProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
  );
});

final notificationFeatureProvider = StateNotifierProvider<
    NotificationNotifier, NotificationFeatureState>((ref) {
  return NotificationNotifier(
    repository: ref.watch(notificationRepositoryProvider),
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
    authProvider: ref.watch(authProvider),
  );
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationFeatureProvider);
  if (state is NotificationsLoaded) {
    return state.unreadCount;
  }
  return 0;
});


class NotificationNotifier extends StateNotifier<NotificationFeatureState> {
  final NotificationRepository _repository;
  final NotificationRemoteDataSource _remoteDataSource;
  final AppAuthState _authState;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription? _realtimeSubscription;

  NotificationNotifier({
    required NotificationRepository repository,
    required NotificationRemoteDataSource remoteDataSource,
    required AppAuthState authProvider,
  })  : _repository = repository,
        _remoteDataSource = remoteDataSource,
        _authState = authProvider,
        super(const NotificationInitial()) {
    _initRealtimeSubscription();
  }

  void _initRealtimeSubscription() {
    final userId = _currentUserId;
    if (userId == null) return;

    _realtimeChannel = _remoteDataSource.subscribeToRealtime(
      userId: userId,
      onNewNotification: (notification) {
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

  String? get _currentUserId {
    final auth = _authState;
    if (auth is AppAuthAuthenticated) {
      return auth.userId;
    }
    return null;
  }

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

  Future<void> markRead(String notificationId) async {
    final result = await _repository.markRead(notificationId);

    result.fold(
      (failure) {
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

  Future<void> markAllRead() async {
    final result = await _repository.markAllRead();

    result.fold(
      (failure) {
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

  Future<void> loadMore({String? type}) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;
    if (!current.hasMore) return;

    await loadNotifications(
      type: type ?? current.activeFilter,
      page: current.page + 1,
    );
  }

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
