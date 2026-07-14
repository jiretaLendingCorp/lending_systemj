// lib/features/borrowers/presentation/widgets/next_payment_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';

class NextPaymentCard extends StatelessWidget {
  final Loan loan;

  const NextPaymentCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = loan.dueAt;
    if (dueDate == null) return const SizedBox.shrink();

    final daysRemaining = DateFormatter.daysRemaining(dueDate);
    final daysOverdue = DateFormatter.daysOverdue(dueDate);
    final isOverdue = daysOverdue > 0;
    final isUrgent = !isOverdue && daysRemaining <= 3;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: (isOverdue
                  ? ColorTokens.lightError
                  : isUrgent
                      ? ColorTokens.lightWarning
                      : ColorTokens.lightBorder)
              .withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Payment',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                _DueBadge(
                  isOverdue: isOverdue,
                  isUrgent: isUrgent,
                  daysRemaining: daysRemaining,
                  daysOverdue: daysOverdue,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: isOverdue
                      ? ColorTokens.lightError
                      : isUrgent
                          ? ColorTokens.lightWarning
                          : theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.formatDisplayDate(dueDate),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Due',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPhp(loan.outstandingBalance),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverdue
                            ? ColorTokens.lightError
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: () {
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: isOverdue
                        ? ColorTokens.lightError
                        : ColorTokens.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Pay Now'),
                ),
              ],
            ),

            if (isOverdue && loan.penaltyAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorTokens.lightError.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: ColorTokens.lightError),
                    const SizedBox(width: 8),
                    Text(
                      'Penalty: ${CurrencyFormatter.formatPhp(loan.penaltyAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorTokens.lightError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final bool isOverdue;
  final bool isUrgent;
  final int daysRemaining;
  final int daysOverdue;

  const _DueBadge({
    required this.isOverdue,
    required this.isUrgent,
    required this.daysRemaining,
    required this.daysOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverdue
        ? ColorTokens.lightError
        : isUrgent
            ? ColorTokens.lightWarning
            : ColorTokens.lightSuccess;

    final text = isOverdue
        ? '$daysOverdue day${daysOverdue != 1 ? 's' : ''} overdue'
        : daysRemaining == 0
            ? 'Due today'
            : '$daysRemaining day${daysRemaining != 1 ? 's' : ''} left';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
