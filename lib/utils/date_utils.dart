import 'package:intl/intl.dart';

/// Date helpers for IULMS.
class DateUtilsX {
  const DateUtilsX._();

  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  static String formatShort(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  static String daysLeft(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue by ${-diff}d';
    if (diff == 0) return 'Due today';
    return '$diff day${diff == 1 ? '' : 's'} left';
  }

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
