// lib/shared/widgets/currency_text.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';

class CurrencyText extends StatelessWidget {
  final double amount;

  final TextStyle? style;

  final bool compact;

  final bool showSymbol;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.compact = false,
    this.showSymbol = true,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = compact
        ? CurrencyFormatter.formatPhpCompact(amount)
        : CurrencyFormatter.formatPhp(amount);

    final effectiveStyle = style ??
        DefaultTextStyle.of(context).style.copyWith(
              fontWeight: FontWeight.w600,
            );

    return Text(
      showSymbol ? formatted : CurrencyFormatter.formatAmount(amount),
      style: effectiveStyle,
    );
  }
}
