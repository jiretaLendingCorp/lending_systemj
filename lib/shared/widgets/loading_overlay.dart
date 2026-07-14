import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';

/// Full-screen semi-transparent loading overlay with CircularProgressIndicator.
///
/// Use this widget to block interaction while an async operation is
/// in progress. It paints a barrier over the parent and shows a
/// centered spinner with an optional message.
///
/// ```dart
/// Stack(
///   children: [
///     MyContent(),
///     if (isLoading) const LoadingOverlay(message: 'Saving...'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  /// Optional message displayed below the spinner.
  final String? message;

  /// Whether to show the overlay. When `false`, returns [SizedBox.shrink].
  final bool isLoading;

  /// Override the default barrier color.
  final Color? barrierColor;

  /// Override the default spinner color.
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    this.message,
    this.isLoading = true,
    this.barrierColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    final effectiveBarrier =
        barrierColor ?? Colors.black.withValues(alpha: 0.45);
    final effectiveIndicator =
        indicatorColor ?? ColorTokens.accent;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: effectiveBarrier,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    effectiveIndicator,
                  ),
                  strokeWidth: 3.5,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
