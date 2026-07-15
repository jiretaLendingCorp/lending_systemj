// lib/features/borrowers/presentation/pages/borrower_notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LenderNotificationsPage extends ConsumerStatefulWidget {
  const LenderNotificationsPage({super.key});

  @override
  ConsumerState<LenderNotificationsPage> createState() =>
      _BorrowerNotificationsPageState();
}

class _BorrowerNotificationsPageState
    extends ConsumerState<LenderNotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationFeatureProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifState = ref.watch(notificationFeatureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (notifState is NotificationsLoaded &&
              notifState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref
                    .read(notificationFeatureProvider.notifier)
                    .markAllRead();
              },
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(notificationFeatureProvider.notifier)
            .loadNotifications(),
        child: _buildBody(theme, notifState),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, NotificationFeatureState notifState) {
    if (notifState is NotificationLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifState is NotificationError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(notifState.message, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(notificationFeatureProvider.notifier)
                  .loadNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notifState is NotificationsLoaded) {
      if (notifState.notifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bell,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifState.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = notifState.notifications[index];
          return _NotificationItem(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                ref
                    .read(notificationFeatureProvider.notifier)
                    .markRead(notification.id);
              }
            },
          );
        },
      );
    }

    return const Center(child: Text('Loading notifications...'));
  }
}

class _NotificationItem extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !(notification.isRead as bool);

    return Card(
      color: isUnread ? ColorTokens.accent.withValues(alpha: 0.03) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: const BoxDecoration(
                    color: ColorTokens.accent,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title as String? ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body as String? ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
