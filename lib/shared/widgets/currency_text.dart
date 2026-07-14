import 'package:flutter/material.dart';
import 'package:lendflow/core/utils/currency_formatter.dart';

/// PHP currency display widget using [CurrencyFormatter].
///
/// Formats a numeric `amount` as Philippine Peso (₱) and renders it
/// with an optional custom text style. Supports compact (no decimals)
/// and full formatting modes.
///
/// ```dart
/// CurrencyText(amount: 12500.75)                         // ₱12,500.75
/// CurrencyText(amount: 12500.75, compact: true)          // ₱12,501
/// CurrencyText(amount: 12500.75, style: TextStyle(...))  // with custom style
/// ```
class CurrencyText extends StatelessWidget {
  /// The monetary amount to format and display.
  final double amount;

  /// Optional text style override.
  final TextStyle? style;

  /// When `true`, omits decimal places. Defaults to `false`.
  final bool compact;

  /// Whether to show the currency symbol. Defaults to `true`.
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
