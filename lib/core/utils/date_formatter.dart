// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';
import 'package:jireta_loan/core/utils/constants.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  static String formatDisplayDateTime(DateTime date) {
    return DateFormat(AppConstants.displayDateTimeFormat).format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat(AppConstants.timeFormat).format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeksw ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsmo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$yearsy ago';
    }
  }

  static DateTime? parseDate(String dateStr) {
    return DateFormat(AppConstants.dateFormat).tryParse(dateStr);
  }

  static DateTime? parseDateTime(String dateStr) {
    return DateFormat(AppConstants.dateTimeFormat).tryParse(dateStr);
  }

  static DateTime? parseIso8601(String dateStr) {
    return DateTime.tryParse(dateStr);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static int daysOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final adjustedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final adjustedNow = DateTime(now.year, now.month, now.day);
    final diff = adjustedNow.difference(adjustedDue).inDays;
    return diff > AppConstants.paymentOverdueGraceDays
        ? diff - AppConstants.paymentOverdueGraceDays
        : 0;
  }

  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final adjustedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final adjustedNow = DateTime(now.year, now.month, now.day);
    final diff = adjustedDue.difference(adjustedNow).inDays;
    return diff > 0 ? diff : 0;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static String formatDueDate(DateTime dueDate) {
    final overdue = daysOverdue(dueDate);
    if (overdue > 0) {
      return '${formatDisplayDate(dueDate)} ($overdue days overdue)';
    }
    final remaining = daysRemaining(dueDate);
    if (remaining <= 3) {
      return '${formatDisplayDate(dueDate)} ($remaining days left)';
    }
    return formatDisplayDate(dueDate);
  }
}
