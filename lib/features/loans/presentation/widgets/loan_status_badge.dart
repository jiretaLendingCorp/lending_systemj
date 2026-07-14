import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';

/// Color-coded loan status badge widget.
///
/// Displays the loan's current status with a distinctive background
/// color and icon, providing visual status indication at a glance.
class LoanStatusBadge extends StatelessWidget {
  final LoanStatus status;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;
  final bool showIcon;

  const LoanStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.iconSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _statusIcon,
              size: iconSize,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor => switch (status) {
        LoanStatus.draft => ColorTokens.lightTextSecondary,
        LoanStatus.submitted => ColorTokens.lightInfo,
        LoanStatus.underReview => ColorTokens.lightWarning,
        LoanStatus.approved => ColorTokens.lightSuccess,
        LoanStatus.disbursed => ColorTokens.accent,
        LoanStatus.active => ColorTokens.loanActive,
        LoanStatus.paid => ColorTokens.loanPaid,
        LoanStatus.defaulted => ColorTokens.loanOverdue,
        LoanStatus.rejected => ColorTokens.lightError,
        LoanStatus.closed => ColorTokens.lightTextSecondary,
      };

  IconData get _statusIcon => switch (status) {
        LoanStatus.draft => Icons.edit_note_rounded,
        LoanStatus.submitted => Icons.send_rounded,
        LoanStatus.underReview => Icons.search_rounded,
        LoanStatus.approved => Icons.check_circle_outline_rounded,
        LoanStatus.disbursed => Icons.account_balance_outlined,
        LoanStatus.active => Icons.play_circle_outline_rounded,
        LoanStatus.paid => Icons.verified_rounded,
        LoanStatus.defaulted => Icons.error_outline_rounded,
        LoanStatus.rejected => Icons.cancel_outlined,
        LoanStatus.closed => Icons.lock_outline_rounded,
      };
}
