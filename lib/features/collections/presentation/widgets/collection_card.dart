import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/currency_formatter.dart';
import 'package:lendflow/core/utils/date_formatter.dart';
import 'package:lendflow/features/collections/domain/entities/collection.dart';

/// Collection summary card widget for list views.
///
/// Displays key collection information including loan ID, borrower,
/// amount, method, status, rider info, and GPS verification badge.
class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;
  final VoidCallback? onAssignRider;

  const CollectionCard({
    super.key,
    required this.collection,
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
              // Row 1: Loan ID + Amount + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        collection.method.iconData,
                        size: 18,
                        color: _methodColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loan #${collection.loanId.length > 8 ? collection.loanId.substring(0, 8).toUpperCase() : collection.loanId.toUpperCase()}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  _CollectionStatusBadge(status: collection.status),
                ],
              ),
              const SizedBox(height: 8),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.formatPhp(collection.amount),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.accent,
                        ),
                  ),
                  Text(
                    DateFormatter.formatDisplayDate(collection.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Method, Rider info
              Row(
                children: [
                  Expanded(
                    child: _InfoColumn(
                      label: 'Method',
                      value: collection.method.label,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _InfoColumn(
                      label: 'Rider',
                      value: collection.riderName ?? 'Unassigned',
                      isDark: isDark,
                      valueColor: collection.hasRiderAssigned
                          ? ColorTokens.roleRider
                          : ColorTokens.lightWarning,
                    ),
                  ),
                  Expanded(
                    child: _InfoColumn(
                      label: 'Borrower',
                      value:
                          '#${collection.borrowerId.length > 6 ? collection.borrowerId.substring(0, 6).toUpperCase() : collection.borrowerId.toUpperCase()}',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              // GPS verification badge for collected
              if (collection.isCollected &&
                  collection.hasGpsCoordinates) ...[
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
                        Icons.gps_fixed_rounded,
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

              // Assign rider button
              if (onAssignRider != null &&
                  collection.status.isActionable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: onAssignRider,
                    icon:
                        const Icon(Icons.person_add_rounded, size: 16),
                    label: Text(
                      collection.hasRiderAssigned
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _methodColor => switch (collection.method) {
        CollectionMethod.gcash => const Color(0xFF007BFF),
        CollectionMethod.office => ColorTokens.secondaryAccent,
        CollectionMethod.cash => ColorTokens.lightSuccess,
      };
}

/// Status badge for collection cards.
class _CollectionStatusBadge extends StatelessWidget {
  final CollectionStatus status;

  const _CollectionStatusBadge({required this.status});

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
        CollectionStatus.pending => ColorTokens.lightWarning,
        CollectionStatus.assigned => ColorTokens.lightInfo,
        CollectionStatus.inTransit => const Color(0xFF7C4DFF),
        CollectionStatus.collected => ColorTokens.lightSuccess,
        CollectionStatus.failed => ColorTokens.lightError,
      };
}

/// Helper widget for displaying a label-value pair.
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
