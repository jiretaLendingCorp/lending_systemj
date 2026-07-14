import 'package:intl/intl.dart';
import 'package:lendflow/core/utils/constants.dart';

/// Date formatting utilities configured for Philippine timezone (Asia/Manila).
class DateFormatter {
  DateFormatter._();

  /// Format a [DateTime] as `yyyy-MM-dd`.
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format a [DateTime] as `yyyy-MM-dd HH:mm:ss`.
  static String formatDateTime(DateTime date) {
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  /// Format a [DateTime] for display: `MMM dd, yyyy`.
  ///
  /// Example: `Jan 15, 2025`
  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  /// Format a [DateTime] for display: `MMM dd, yyyy hh:mm a`.
  ///
  /// Example: `Jan 15, 2025 02:30 PM`
  static String formatDisplayDateTime(DateTime date) {
    return DateFormat(AppConstants.displayDateTimeFormat).format(date);
  }

  /// Format a [DateTime] as time only: `hh:mm a`.
  ///
  /// Example: `02:30 PM`
  static String formatTime(DateTime date) {
    return DateFormat(AppConstants.timeFormat).format(date);
  }

  /// Format a [DateTime] as a relative time string.
  ///
  /// Returns strings like "just now", "5m ago", "2h ago", "3d ago".
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
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Parse a date string in `yyyy-MM-dd` format.
  static DateTime? parseDate(String dateStr) {
    return DateFormat(AppConstants.dateFormat).tryParse(dateStr);
  }

  /// Parse a date-time string in `yyyy-MM-dd HH:mm:ss` format.
  static DateTime? parseDateTime(String dateStr) {
    return DateFormat(AppConstants.dateTimeFormat).tryParse(dateStr);
  }

  /// Parse an ISO-8601 date string.
  static DateTime? parseIso8601(String dateStr) {
    return DateTime.tryParse(dateStr);
  }

  /// Check if a [DateTime] is today (in Philippine timezone).
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a [DateTime] is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Calculate the number of days overdue from a [dueDate].
  ///
  /// Returns 0 if not overdue.
  static int daysOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final adjustedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final adjustedNow = DateTime(now.year, now.month, now.day);
    final diff = adjustedNow.difference(adjustedDue).inDays;
    return diff > AppConstants.paymentOverdueGraceDays
        ? diff - AppConstants.paymentOverdueGraceDays
        : 0;
  }

  /// Calculate days remaining until [dueDate].
  ///
  /// Returns 0 if already past due (grace period excluded).
  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final adjustedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final adjustedNow = DateTime(now.year, now.month, now.day);
    final diff = adjustedDue.difference(adjustedNow).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Get the start of today (midnight).
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get the end of today (23:59:59.999).
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get a formatted due-date string with overdue indicator.
  ///
  /// Example: "Jan 15, 2025 (3 days overdue)"
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
