// lib/features/loans/presentation/widgets/loan_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/presentation/widgets/loan_status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onTap;

  const LoanCard({
    super.key,
    required this.loan,
    this.onTap,
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
                  Expanded(
                    child: Text(
                      'Loan #${loan.id.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  LoanStatusBadge(status: loan.status),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _InfoColumn(
                      label: 'Principal',
                      value: CurrencyFormatter.formatPhp(loan.principal),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _InfoColumn(
                      label: 'Total Payable',
                      value: CurrencyFormatter.formatPhp(loan.totalPayable),
                      isDark: isDark,
                      valueColor: loan.status.isActive
                          ? ColorTokens.accent
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _InfoColumn(
                      label: 'Term',
                      value: '${loan.termDays} days',
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _InfoColumn(
                      label: 'Schedule',
                      value: loan.scheduleType.label,
                      isDark: isDark,
                    ),
                  ),
                  if (loan.dueAt != null)
                    Expanded(
                      child: _InfoColumn(
                        label: 'Due Date',
                        value: DateFormatter.formatDisplayDate(loan.dueAt!),
                        isDark: isDark,
                        valueColor: loan.status == LoanStatus.defaulted
                            ? ColorTokens.lightError
                            : null,
                      ),
                    ),
                ],
              ),

              if (loan.status.isActive && loan.outstandingBalance > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: loan.repaymentProgress,
                    backgroundColor: isDark
                        ? ColorTokens.darkBorder
                        : ColorTokens.lightBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      loan.status == LoanStatus.defaulted
                          ? ColorTokens.lightError
                          : ColorTokens.accent,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outstanding: ${CurrencyFormatter.formatPhp(loan.outstandingBalance)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? ColorTokens.darkTextSecondary
                                : ColorTokens.lightTextSecondary,
                          ),
                    ),
                    Text(
                      '${(loan.repaymentProgress * 100).toStringAsFixed(0)}% paid',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorTokens.accent,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],

              if (loan.penaltyAmount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 14,
                        color: ColorTokens.lightError,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Penalty: ${CurrencyFormatter.formatPhp(loan.penaltyAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ColorTokens.lightError,
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
