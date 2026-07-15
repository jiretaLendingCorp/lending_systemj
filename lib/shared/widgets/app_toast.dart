// lib/shared/widgets/app_toast.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';

enum ToastType { success, error, warning, info }

class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _ToastContent(
            message: message,
            type: type,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
  }
}

class _ToastContent extends StatelessWidget {
  final String message;
  final ToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastContent({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final palette = _resolvePalette(type, isLight);
    final icon = _resolveIcon(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: palette.iconFg, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: palette.iconFg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _resolveIcon(ToastType type) {
    return switch (type) {
      ToastType.success => LucideIcons.circleCheck,
      ToastType.error => LucideIcons.circleAlert,
      ToastType.warning => LucideIcons.triangleAlert,
      ToastType.info => LucideIcons.info,
    };
  }

  _ToastPalette _resolvePalette(ToastType type, bool isLight) {
    switch (type) {
      case ToastType.success:
        return _ToastPalette(
          bg: isLight ? const Color(0xFFF0FDF4) : const Color(0xFF0B1F14),
          border: ColorTokens.lightSuccess.withValues(alpha: 0.25),
          iconBg: ColorTokens.lightSuccess.withValues(alpha: 0.15),
          iconFg: ColorTokens.lightSuccess,
          text: isLight ? const Color(0xFF14532D) : ColorTokens.darkText,
        );
      case ToastType.error:
        return _ToastPalette(
          bg: isLight ? const Color(0xFFFEF2F2) : const Color(0xFF1F0B0B),
          border: ColorTokens.lightError.withValues(alpha: 0.25),
          iconBg: ColorTokens.lightError.withValues(alpha: 0.15),
          iconFg: ColorTokens.lightError,
          text: isLight ? const Color(0xFF7F1D1D) : ColorTokens.darkText,
        );
      case ToastType.warning:
        return _ToastPalette(
          bg: isLight ? const Color(0xFFFFFBEB) : const Color(0xFF1F1608),
          border: ColorTokens.lightWarning.withValues(alpha: 0.3),
          iconBg: ColorTokens.lightWarning.withValues(alpha: 0.15),
          iconFg: ColorTokens.lightWarning,
          text: isLight ? const Color(0xFF7C2D12) : ColorTokens.darkText,
        );
      case ToastType.info:
        return _ToastPalette(
          bg: isLight ? const Color(0xFFEFF6FF) : const Color(0xFF0B1620),
          border: ColorTokens.lightInfo.withValues(alpha: 0.25),
          iconBg: ColorTokens.lightInfo.withValues(alpha: 0.15),
          iconFg: ColorTokens.lightInfo,
          text: isLight ? const Color(0xFF1E3A8A) : ColorTokens.darkText,
        );
    }
  }
}

class _ToastPalette {
  final Color bg;
  final Color border;
  final Color iconBg;
  final Color iconFg;
  final Color text;

  const _ToastPalette({
    required this.bg,
    required this.border,
    required this.iconBg,
    required this.iconFg,
    required this.text,
  });
}
