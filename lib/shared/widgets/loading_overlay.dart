// lib/shared/widgets/loading_overlay.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;

  final bool isLoading;

  final Color? barrierColor;

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
        barrierColor ?? Colors.black.withOpacity(0.45);
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
