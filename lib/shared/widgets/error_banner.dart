import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';

/// Inline error banner with red background, error message, and retry button.
///
/// Displays a dismissible or retryable error message at the top of a
/// content area. Useful for showing network failures, validation errors,
/// or any recoverable error state.
///
/// ```dart
/// if (error != null)
///   ErrorBanner(
///     message: error,
///     onRetry: () => ref.read(provider.notifier).reload(),
///   )
/// ```
class ErrorBanner extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Optional callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Optional callback when the dismiss button is pressed.
  final VoidCallback? onDismiss;

  /// Whether to show the retry button. Defaults to `true`.
  final bool showRetry;

  /// Whether to show the dismiss button. Defaults to `true`.
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
