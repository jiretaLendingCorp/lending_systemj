// lib/core/utils/validators.dart
import 'package:jireta_loan/core/utils/constants.dart';

class Validators {
  Validators._();


  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
    );
    if (!regex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }


  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final regex = RegExp(r'^(\+63|0)?9\d{9}$');
    if (!regex.hasMatch(digits)) {
      return 'Please enter a valid Philippine mobile number';
    }
    return null;
  }


  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }


  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    final digits = value.trim();
    if (digits.length != AppConstants.otpLength) {
      return 'OTP must be ${AppConstants.otpLength} digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return 'OTP must contain only digits';
    }
    return null;
  }


  static String? loanAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Loan amount is required';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount < AppConstants.minLoanAmount) {
      return 'Minimum loan amount is ${AppConstants.currencySymbol}${AppConstants.minLoanAmount.toInt()}';
    }
    if (amount > AppConstants.maxLoanAmount) {
      return 'Maximum loan amount is ${AppConstants.currencySymbol}${AppConstants.maxLoanAmount.toInt()}';
    }
    return null;
  }

  static String? paymentAmount(String? value, {double? outstandingBalance}) {
    if (value == null || value.trim().isEmpty) {
      return 'Payment amount is required';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount < AppConstants.minPaymentAmount) {
      return 'Minimum payment is ${AppConstants.currencySymbol}${AppConstants.minPaymentAmount.toInt()}';
    }
    if (outstandingBalance != null && amount > outstandingBalance) {
      return 'Payment cannot exceed outstanding balance of ${AppConstants.currencySymbol}${outstandingBalance.toStringAsFixed(2)}';
    }
    return null;
  }


  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s'\-\.]+$").hasMatch(value.trim())) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  static String? firstName(String? value) => name(value, fieldName: 'First name');

  static String? lastName(String? value) => name(value, fieldName: 'Last name');


  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }


  static String? notPastDate(DateTime? date, {String fieldName = 'Date'}) {
    if (date == null) {
      return '$fieldName is required';
    }
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    if (dateOnly.isBefore(todayOnly)) {
      return '$fieldName cannot be in the past';
    }
    return null;
  }

  static String? notFutureDate(DateTime? date, {String fieldName = 'Date'}) {
    if (date == null) {
      return '$fieldName is required';
    }
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    if (dateOnly.isAfter(todayOnly)) {
      return '$fieldName cannot be in the future';
    }
    return null;
  }


  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}
