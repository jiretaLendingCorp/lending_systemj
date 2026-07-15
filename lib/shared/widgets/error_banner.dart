// lib/shared/widgets/error_banner.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';

class ErrorBanner extends StatelessWidget {
  final String message;

  final VoidCallback? onRetry;

  final VoidCallback? onDismiss;

  final bool showRetry;

  final bool showDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.showRetry = true,
    this.showDismiss = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorTokens.lightError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorTokens.lightError.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: ColorTokens.lightError,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyles.bodyMedium(context).copyWith(
                color: ColorTokens.lightError,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showRetry) ...[
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Retry',
              color: ColorTokens.lightError,
              onPressed: onRetry,
            ),
          ],
          if (showDismiss) ...[
            const SizedBox(width: 4),
            _ActionButton(
              label: 'Dismiss',
              color: theme.brightness == Brightness.light
                  ? ColorTokens.lightTextSecondary
                  : ColorTokens.darkTextSecondary,
              onPressed: onDismiss ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
