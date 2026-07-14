import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/features/notifications/presentation/providers/notification_notifier.dart';

/// Unread count badge widget for use in app bars and bottom navigation.
///
/// Displays a small red circle with the unread notification count.
/// Hidden when count is zero.
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final double badgeSize;
  final double fontSize;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeSize = 18,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (unreadCount == 0) return child;

    return Badge(
      label: Text(
        unreadCount > 99 ? '99+' : '$unreadCount',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: ColorTokens.lightError,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: child,
    );
  }
}
