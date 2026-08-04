import 'package:intl/intl.dart';

abstract final class WmsFormatters {
  static String currency(num? value) {
    if (value == null) return '—';
    return NumberFormat.simpleCurrency().format(value);
  }

  static String quantity(num? value) {
    if (value == null) return '—';
    return NumberFormat.decimalPattern().format(value);
  }

  static String relativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = dateTime.difference(DateTime.now());
    final abs = diff.abs();
    final past = diff.isNegative;
    if (abs.inMinutes < 60) {
      final m = abs.inMinutes;
      return past ? '${m}m ago' : 'in ${m}m';
    }
    if (abs.inHours < 24) {
      final h = abs.inHours;
      return past ? '${h}h ago' : 'in ${h}h';
    }
    final d = abs.inDays;
    return past ? '${d}d ago' : 'in ${d}d';
  }

  /// Relative time plus absolute stamp for notification centers.
  static String notificationTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final relative = relativeTime(dateTime);
    final absolute = DateFormat('MMM d · h:mm a').format(dateTime);
    if (relative.isEmpty) return absolute;
    return '$relative · $absolute';
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String headerDateTime() {
    final now = DateTime.now();
    final date = DateFormat('EEE, MMM d').format(now);
    final time = DateFormat('h:mm a').format(now);
    return '$date · $time · Warehouse Operations';
  }

  /// Live date and time for staff dashboard welcome header.
  static String staffDashboardDateTime([DateTime? at]) {
    final now = at ?? DateTime.now();
    final date = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final time = DateFormat('h:mm a').format(now);
    return '$date · $time';
  }

  /// First name for personalized greetings.
  static String greetingName(String? fullName) {
    final trimmed = fullName?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static String dateShort(DateTime? dateTime) {
    if (dateTime == null) return '—';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  static String dateTimeShort(DateTime? dateTime) {
    if (dateTime == null) return '—';
    return DateFormat('MMM d, yyyy · h:mm a').format(dateTime);
  }
}
