import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/date_formatter.dart';
import 'package:lendflow/features/notifications/domain/entities/app_notification.dart';

/// Card widget for displaying a single notification item.
///
/// Features:
/// - Type-specific icon with colored background
/// - Unread indicator (blue dot)
/// - Title and body text
/// - Relative timestamp
/// - Tap handler for marking as read
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColor;
    final typeIcon = _typeIcon;

    return Card(
      color: notification.isRead
          ? null
          : ColorTokens.accent.withOpacity(0.03),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with unread dot
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: ColorTokens.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body text
                    Text(
                      notification.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      DateFormatter.formatRelative(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline.withOpacity(0.7),
                      ),
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

  Color get _typeColor => switch (notification.type) {
        NotificationType.paymentReminder => ColorTokens.lightWarning,
        NotificationType.loanApproved => ColorTokens.lightSuccess,
        NotificationType.loanRejected => ColorTokens.lightError,
        NotificationType.disbursementRider => ColorTokens.accent,
        NotificationType.penaltyApplied => ColorTokens.secondaryAccent,
        NotificationType.general => ColorTokens.lightInfo,
      };

  IconData get _typeIcon => switch (notification.type) {
        NotificationType.paymentReminder => Icons.payment_outlined,
        NotificationType.loanApproved => Icons.check_circle_outline,
        NotificationType.loanRejected => Icons.cancel_outlined,
        NotificationType.disbursementRider => Icons.local_shipping_outlined,
        NotificationType.penaltyApplied => Icons.warning_amber_outlined,
        NotificationType.general => Icons.notifications_outlined,
      };
}
