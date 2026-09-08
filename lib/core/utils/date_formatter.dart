// lib/core/utils/date_formatter.dart
// Date formatting utilities for AKTS

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _displayLongFormat = DateFormat('dd MMMM yyyy');
  static final DateFormat _storageFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _fullFormat = DateFormat('dd-MM-yyyy HH:mm');

  /// Format date for display: 04-09-2026
  static String toDisplayDate(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Format date for display with month name: 04 September 2026
  static String toLongDisplayDate(DateTime date) {
    return _displayLongFormat.format(date);
  }

  /// Format date for storage: 2026-09-04
  static String toStorageDate(DateTime date) {
    return _storageFormat.format(date);
  }

  /// Format time: 14:30
  static String toTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format date and time: 04-09-2026 14:30
  static String toFullDateTime(DateTime date) {
    return _fullFormat.format(date);
  }

  /// Parse a display-format date string to DateTime
  static DateTime? parseDisplayDate(String dateStr) {
    try {
      return _displayFormat.parse(dateStr);
    } catch (_) {
      try {
        return _storageFormat.parse(dateStr);
      } catch (_) {
        return null;
      }
    }
  }

  /// Check if a date is today (in local timezone, or within recent 24h work cycle)
  static bool isToday(DateTime date) {
    final d = date.toLocal();
    final now = DateTime.now().toLocal();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return true;
    }
    // Also include recent receipts created within the last 24 hours across midnight transition
    final diff = now.difference(d);
    return !diff.isNegative && diff.inHours < 24 && (now.day - d.day).abs() <= 1;
  }

  /// Check if a date is in the current month (in local timezone)
  static bool isCurrentMonth(DateTime date) {
    final d = date.toLocal();
    final now = DateTime.now().toLocal();
    return d.year == now.year && d.month == now.month;
  }

  /// Get start of today
  static DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get end of today
  static DateTime get endOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Get start of current month
  static DateTime get startOfCurrentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Get end of current month
  static DateTime get endOfCurrentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Format a relative time description
  static String toRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return toDisplayDate(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
