// lib/features/lenders/presentation/widgets/loan_balance_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';

class LoanBalanceCard extends StatelessWidget {
  final Loan loan;

  const LoanBalanceCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: ColorTokens.accent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Loan Balance',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loan.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              CurrencyFormatter.formatPhp(loan.outstandingBalance),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'of ${CurrencyFormatter.formatPhp(loan.totalPayable)} total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repayment Progress',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '${(loan.repaymentProgress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: loan.repaymentProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _detailItem(
                  'Interest',
                  '${(loan.interestRate * 100).toStringAsFixed(0)}%',
                ),
                _detailItem(
                  'Term',
                  '${loan.termDays} days',
                ),
                _detailItem(
                  'Schedule',
                  loan.scheduleType.label,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
