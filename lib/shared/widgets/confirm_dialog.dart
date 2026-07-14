import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';

/// Confirmation dialog with title, message, confirm (destructive) and cancel buttons.
///
/// Designed for destructive or irreversible actions such as deleting
/// records, rejecting loans, or cancelling operations.
///
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: 'Delete User',
///   message: 'This action cannot be undone. Are you sure?',
/// );
/// if (confirmed == true) { ... }
/// ```
class ConfirmDialog extends StatelessWidget {
  /// Dialog title.
  final String title;

  /// Descriptive message explaining the consequence of the action.
  final String message;

  /// Label for the confirm button. Defaults to 'Confirm'.
  final String confirmLabel;

  /// Label for the cancel button. Defaults to 'Cancel'.
  final String cancelLabel;

  /// Whether the confirm button should use a destructive (red) style.
  /// Defaults to `true`.
  final bool isDestructive;

  /// Optional icon displayed above the title.
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
    this.icon,
  });

  /// Convenience method to show the dialog and return a `bool?`.
  ///
  /// Returns `true` when the confirm button is pressed, `false` or
  /// `null` when cancelled or dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor =
        isDestructive ? ColorTokens.lightError : ColorTokens.accent;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: confirmColor),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyles.titleLarge(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyles.bodyMedium(context).copyWith(
          color: theme.brightness == Brightness.light
              ? ColorTokens.lightTextSecondary
              : ColorTokens.darkTextSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(
              color: theme.brightness == Brightness.light
                  ? ColorTokens.lightTextSecondary
                  : ColorTokens.darkTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
