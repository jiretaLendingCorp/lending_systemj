import 'package:intl/intl.dart';
import 'package:lendflow/core/utils/constants.dart';

/// PHP currency formatting utilities for LendFlow.
///
/// All monetary values in the system are in Philippine Pesos (₱).
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format a numeric [value] as PHP currency string.
  ///
  /// Example: `formatPhp(1234.5)` → `₱1,234.50`
  static String formatPhp(num value) {
    return NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
      locale: AppConstants.locale,
    ).format(value);
  }

  /// Format a numeric [value] as PHP currency without decimal places.
  ///
  /// Example: `formatPhpCompact(1234.5)` → `₱1,235`
  static String formatPhpCompact(num value) {
    return NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
      locale: AppConstants.locale,
    ).format(value);
  }

  /// Format a numeric [value] as a plain decimal string (no symbol).
  ///
  /// Example: `formatAmount(1234.5)` → `1,234.50`
  static String formatAmount(num value) {
    return NumberFormat.decimalPatternDigits(
      decimalDigits: 2,
      locale: AppConstants.locale,
    ).format(value);
  }

  /// Parse a PHP-formatted string back to a [double].
  ///
  /// Strips the ₱ symbol and commas before parsing.
  /// Returns `0.0` if parsing fails.
  static double parsePhp(String value) {
    final cleaned = value
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Calculate the total repayment for a loan.
  ///
  /// `principal` × (1 + interestRate)
  static double calculateTotalRepayment(double principal) {
    return principal * (1 + AppConstants.interestRate);
  }

  /// Calculate the interest amount for a loan.
  ///
  /// `principal` × interestRate
  static double calculateInterest(double principal) {
    return principal * AppConstants.interestRate;
  }

  /// Calculate the penalty for an overdue amount.
  ///
  /// `overdueAmount` × penaltyRate
  static double calculatePenalty(double overdueAmount) {
    return overdueAmount * AppConstants.penaltyRate;
  }

  /// Calculate the total amount due including penalty.
  static double calculateTotalWithPenalty(double overdueAmount) {
    return overdueAmount + calculatePenalty(overdueAmount);
  }

  /// Check if [amount] falls within the allowed loan range.
  static bool isWithinLoanRange(double amount) {
    return amount >= AppConstants.minLoanAmount &&
        amount <= AppConstants.maxLoanAmount;
  }

  /// Format a percentage value for display.
  ///
  /// Example: `formatPercentage(0.20)` → `20%`
  static String formatPercentage(double value, {int decimalDigits = 0}) {
    return '${(value * 100).toStringAsFixed(decimalDigits)}%';
  }
}
