import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';

/// Empty state widget with icon, title, subtitle, and optional action button.
///
/// Used when a list, table, or content area has no data to display.
/// Provides a friendly visual cue with an optional call-to-action.
///
/// ```dart
/// EmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No loans found',
///   subtitle: 'Create your first loan to get started',
///   actionLabel: 'Create Loan',
///   onAction: () => context.go('/admin/loans/create'),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Icon displayed above the title.
  final IconData icon;

  /// Primary message.
  final String title;

  /// Secondary descriptive message.
  final String? subtitle;

  /// Label for the optional action button.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Override the default icon size.
  final double iconSize;

  /// Override the default icon color.
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ??
        (theme.brightness == Brightness.light
            ? ColorTokens.lightDisabled
            : ColorTokens.darkDisabled);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyles.titleLarge(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyles.bodyMedium(context).copyWith(
                  color: theme.brightness == Brightness.light
                      ? ColorTokens.lightTextSecondary
                      : ColorTokens.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
