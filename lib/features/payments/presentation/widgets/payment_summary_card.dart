// lib/features/payments/presentation/widgets/payment_summary_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';

class PaymentSummaryCard extends StatelessWidget {
  final double amount;
  final PaymentMethod method;

  const PaymentSummaryCard({
    super.key,
    required this.amount,
    required this.method,
  });

  double get _convenienceFee => method == PaymentMethod.gcash ? 15.0 : 0.0;

  double get _totalAmount => amount + _convenienceFee;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: ColorTokens.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorTokens.accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _SummaryRow(
            label: 'Payment Amount',
            value: CurrencyFormatter.formatPhp(amount),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _SummaryRow(
            label: 'Payment Method',
            value: method.label,
            isDark: isDark,
            icon: method.iconData,
            iconColor: _methodColor,
          ),
          const SizedBox(height: 8),

          if (_convenienceFee > 0) ...[
            _SummaryRow(
              label: 'Convenience Fee',
              value: CurrencyFormatter.formatPhp(_convenienceFee),
              isDark: isDark,
              valueColor: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                CurrencyFormatter.formatPhp(_totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ColorTokens.accent,
                    ),
              ),
            ],
          ),

          if (method == PaymentMethod.gcash) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF007BFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: const Color(0xFF007BFF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will be redirected to GCash to complete payment.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF007BFF),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (method == PaymentMethod.office) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorTokens.secondaryAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: ColorTokens.secondaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bring this reference number when paying at the office.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorTokens.secondaryAccent,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (method == PaymentMethod.cash) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorTokens.lightSuccess.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: ColorTokens.lightSuccess,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A rider will be assigned to collect your cash payment.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorTokens.lightSuccess,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _methodColor => switch (method) {
        PaymentMethod.gcash => const Color(0xFF007BFF),
        PaymentMethod.office => ColorTokens.secondaryAccent,
        PaymentMethod.cash => ColorTokens.lightSuccess,
      };
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? ColorTokens.darkTextSecondary
                : ColorTokens.lightTextSecondary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark
                        ? ColorTokens.darkText
                        : ColorTokens.lightText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
