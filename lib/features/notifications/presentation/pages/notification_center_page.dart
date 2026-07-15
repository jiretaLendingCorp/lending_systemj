// lib/features/notifications/presentation/pages/notification_center_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:jireta_loan/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:jireta_loan/features/notifications/presentation/widgets/notification_card.dart';

class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() =>
      _NotificationCenterPageState();
}

class _NotificationCenterPageState
    extends ConsumerState<NotificationCenterPage> {
  String? _activeFilter;

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
                ref.read(notificationFeatureProvider.notifier).markAllRead();
              },
              child: Text(
                'Mark All Read',
                style: TextStyle(color: ColorTokens.accent),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(notificationFeatureProvider.notifier)
            .loadNotifications(type: _activeFilter),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip(null, 'All'),
                      const SizedBox(width: 8),
                      _filterChip('payment_reminder', 'Payments'),
                      const SizedBox(width: 8),
                      _filterChip('loan_approved', 'Approved'),
                      const SizedBox(width: 8),
                      _filterChip('loan_rejected', 'Rejected'),
                      const SizedBox(width: 8),
                      _filterChip('penalty_applied', 'Penalties'),
                      const SizedBox(width: 8),
                      _filterChip('disbursement_rider', 'Disbursements'),
                    ],
                  ),
                ),
              ),
            ),

            if (notifState is NotificationLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (notifState is NotificationError)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.circleAlert,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(notifState.message,
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref
                            .read(notificationFeatureProvider.notifier)
                            .loadNotifications(type: _activeFilter),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (notifState is NotificationsLoaded)
              notifState.notifications.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.bell,
                                size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style:
                                  theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ll see payment reminders and updates here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index ==
                                notifState.notifications.length) {
                              if (notifState.hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: () => ref
                                          .read(
                                              notificationFeatureProvider
                                                  .notifier)
                                          .loadMore(
                                              type: _activeFilter),
                                      child: const Text('Load More'),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final notification =
                                notifState.notifications[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NotificationCard(
                                notification: notification,
                                onTap: () {
                                  if (!notification.isRead) {
                                    ref
                                        .read(
                                            notificationFeatureProvider
                                                .notifier)
                                        .markRead(notification.id);
                                  }
                                },
                              ),
                            );
                          },
                          childCount:
                              notifState.notifications.length + 1,
                        ),
                      ),
                    )
            else
              const SliverFillRemaining(
                child:
                    Center(child: Text('Loading notifications...')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String? type, String label) {
    final isActive = _activeFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) {
        setState(() => _activeFilter = type);
        ref
            .read(notificationFeatureProvider.notifier)
            .loadNotifications(type: type);
      },
      selectedColor: ColorTokens.accent.withValues(alpha: 0.15),
      checkmarkColor: ColorTokens.accent,
    );
  }
}
