// lib/core/utils/currency_formatter.dart
import 'package:intl/intl.dart';
import 'package:jireta_loan/core/utils/constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String formatPhp(num value) {
    return NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
      locale: AppConstants.locale,
    ).format(value);
  }

  static String formatPhpCompact(num value) {
    return NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
      locale: AppConstants.locale,
    ).format(value);
  }

  static String formatAmount(num value) {
    return NumberFormat.decimalPatternDigits(
      decimalDigits: 2,
      locale: AppConstants.locale,
    ).format(value);
  }

  static double parsePhp(String value) {
    final cleaned = value
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double calculateTotalRepayment(double principal) {
    return principal * (1 + AppConstants.interestRate);
  }

  static double calculateInterest(double principal) {
    return principal * AppConstants.interestRate;
  }

  static double calculatePenalty(double overdueAmount) {
    return overdueAmount * AppConstants.penaltyRate;
  }

  static double calculateTotalWithPenalty(double overdueAmount) {
    return overdueAmount + calculatePenalty(overdueAmount);
  }

  static bool isWithinLoanRange(double amount) {
    return amount >= AppConstants.minLoanAmount &&
        amount <= AppConstants.maxLoanAmount;
  }

  static String formatPercentage(double value, {int decimalDigits = 0}) {
    return '${(value * 100).toStringAsFixed(decimalDigits)}%';
  }
}
