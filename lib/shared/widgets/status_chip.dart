import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';


/// Generic colored status chip widget.
///
/// Renders a compact label inside a colored rounded rectangle,
/// suitable for displaying loan/payment/collection statuses throughout
/// the application.
///
/// ```dart
/// StatusChip(
///   label: 'Active',
///   statusColor: StatusColor.success,
/// )
/// ```
enum StatusColor {
  success,
  warning,
  error,
  info,
  neutral,
}

/// Maps [StatusColor] to actual [Color] values from [ColorTokens].
Color _statusToColor(StatusColor status, Brightness brightness) {
  return switch (status) {
    StatusColor.success => brightness == Brightness.light
        ? ColorTokens.lightSuccess
        : ColorTokens.darkSuccess,
    StatusColor.warning => brightness == Brightness.light
        ? ColorTokens.lightWarning
        : ColorTokens.darkWarning,
    StatusColor.error => brightness == Brightness.light
        ? ColorTokens.lightError
        : ColorTokens.darkError,
    StatusColor.info => brightness == Brightness.light
        ? ColorTokens.lightInfo
        : ColorTokens.darkInfo,
    StatusColor.neutral => brightness == Brightness.light
        ? ColorTokens.lightDisabled
        : ColorTokens.darkDisabled,
  };
}

class StatusChip extends StatelessWidget {
  /// Text label displayed inside the chip.
  final String label;

  /// Semantic color category for the chip.
  final StatusColor statusColor;

  /// Optional custom color that overrides [statusColor].
  final Color? customColor;

  /// Optional icon displayed before the label.
  final IconData? icon;

  /// Font size for the label text. Defaults to 11.
  final double fontSize;

  const StatusChip({
    super.key,
    required this.label,
    required this.statusColor,
    this.customColor,
    this.icon,
    this.fontSize = 11,
  });

  /// Convenience constructors for common status types.
  const StatusChip.success({
    super.key,
    required this.label,
    this.icon,
    this.fontSize = 11,
  })  : statusColor = StatusColor.success,
        customColor = null;

  const StatusChip.warning({
    super.key,
    required this.label,
    this.icon,
    this.fontSize = 11,
  })  : statusColor = StatusColor.warning,
        customColor = null;

  const StatusChip.error({
    super.key,
    required this.label,
    this.icon,
    this.fontSize = 11,
  })  : statusColor = StatusColor.error,
        customColor = null;

  const StatusChip.info({
    super.key,
    required this.label,
    this.icon,
    this.fontSize = 11,
  })  : statusColor = StatusColor.info,
        customColor = null;

  /// Create a [StatusChip] from a loan status string.
  factory StatusChip.fromLoanStatus(String status, {Key? key}) {
    return switch (status.toLowerCase()) {
      'active' => StatusChip.info(key: key, label: 'Active'),
      'overdue' => StatusChip.error(key: key, label: 'Overdue'),
      'paid' => StatusChip.success(key: key, label: 'Paid'),
      'pending' => StatusChip.warning(key: key, label: 'Pending'),
      'approved' => StatusChip.success(key: key, label: 'Approved'),
      'rejected' => StatusChip.error(key: key, label: 'Rejected'),
      'cancelled' => StatusChip(
          key: key,
          label: 'Cancelled',
          statusColor: StatusColor.neutral,
        ),
      _ => StatusChip(
          key: key,
          label: status,
          statusColor: StatusColor.neutral,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = customColor ?? _statusToColor(statusColor, brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
