// lib/features/disbursements/presentation/widgets/disbursement_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DisbursementCard extends StatelessWidget {
  final Disbursement disbursement;
  final VoidCallback? onTap;
  final VoidCallback? onAssignRider;

  const DisbursementCard({
    super.key,
    required this.disbursement,
    this.onTap,
    this.onAssignRider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        disbursement.method.iconData,
                        size: 18,
                        color: _methodColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loan #${disbursement.loanId.length > 8 ? disbursement.loanId.substring(0, 8).toUpperCase() : disbursement.loanId.toUpperCase()}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  _DisbursementStatusBadge(
                    status: disbursement.status,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _InfoColumn(
                      label: 'Method',
                      value: disbursement.method.label,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _InfoColumn(
                      label: 'Rider',
                      value: disbursement.riderName ?? 'Unassigned',
                      isDark: isDark,
                      valueColor: disbursement.hasRiderAssigned
                          ? ColorTokens.roleRider
                          : ColorTokens.lightWarning,
                    ),
                  ),
                  Expanded(
                    child: _InfoColumn(
                      label: 'Created',
                      value: DateFormatter.formatDisplayDate(
                          disbursement.createdAt),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              if (onAssignRider != null &&
                  disbursement.status.isActionable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: onAssignRider,
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: Text(
                      disbursement.hasRiderAssigned
                          ? 'Reassign Rider'
                          : 'Assign Rider',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.accent,
                      side: BorderSide(color: ColorTokens.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],

              if (disbursement.isDelivered &&
                  disbursement.hasGpsCoordinates) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        ColorTokens.lightSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: ColorTokens.lightSuccess,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ColorTokens.lightSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _methodColor => switch (disbursement.method) {
        DisbursementMethod.gcash => const Color(0xFF007BFF),
        DisbursementMethod.office => ColorTokens.secondaryAccent,
        DisbursementMethod.cash => ColorTokens.lightSuccess,
      };
}

class _DisbursementStatusBadge extends StatelessWidget {
  final DisbursementStatus status;

  const _DisbursementStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          Icon(status.iconData, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
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
        DisbursementStatus.pending => ColorTokens.lightWarning,
        DisbursementStatus.assigned => ColorTokens.lightInfo,
        DisbursementStatus.inTransit => const Color(0xFF7C4DFF),
        DisbursementStatus.delivered => ColorTokens.lightSuccess,
        DisbursementStatus.failed => ColorTokens.lightError,
      };
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? ColorTokens.darkTextSecondary
                : ColorTokens.lightTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (isDark ? ColorTokens.darkText : ColorTokens.lightText),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
