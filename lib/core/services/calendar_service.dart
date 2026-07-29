import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class CalendarService {
  static Future<void> generateAndDownloadICS({
    required String title,
    required String description,
    required String eventDateStr,
    String? zoomLink,
  }) async {
    try {
      final start = DateTime.parse(eventDateStr).toUtc();
      final end = start.add(const Duration(hours: 1));

      String fmt(DateTime d) {
        return d
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first;
      }

      final icsContent = [
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'PRODID:-//Propel//Mentorship//EN',
        'BEGIN:VEVENT',
        'DTSTART:${fmt(start)}Z',
        'DTEND:${fmt(end)}Z',
        'SUMMARY:$title',
        'DESCRIPTION:$description${zoomLink != null && zoomLink.isNotEmpty ? '\\nJoin: $zoomLink' : ''}',
        if (zoomLink != null && zoomLink.isNotEmpty) 'URL:$zoomLink',
        'UID:${DateTime.now().millisecondsSinceEpoch}@propel.app',
        'END:VEVENT',
        'END:VCALENDAR',
      ].join('\r\n');

      final bytes = utf8.encode(icsContent);
      final base64Content = base64Encode(bytes);
      final dataUri = Uri.parse('data:text/calendar;charset=utf-8;base64,$base64Content');

      if (await canLaunchUrl(dataUri)) {
        await launchUrl(dataUri);
      }
    } catch (e) {
      // Fallback log or handle
      print('[CalendarService] Export Error: $e');
    }
  }
}
