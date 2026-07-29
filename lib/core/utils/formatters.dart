import 'package:intl/intl.dart';

class AppFormatters {
  static String formatDate(String? isoDateStr) {
    if (isoDateStr == null || isoDateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoDateStr).toLocal();
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (_) {
      return isoDateStr;
    }
  }

  static String formatDateTime(String? isoDateStr) {
    if (isoDateStr == null || isoDateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoDateStr).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (_) {
      return isoDateStr;
    }
  }

  static String formatTimeAgo(String? isoDateStr) {
    if (isoDateStr == null || isoDateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoDateStr).toLocal();
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays > 7) {
        return DateFormat('MMM d').format(dateTime);
      } else if (diff.inDays >= 1) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours >= 1) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes >= 1) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return isoDateStr;
    }
  }
}
