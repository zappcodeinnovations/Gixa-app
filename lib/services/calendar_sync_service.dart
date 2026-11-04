import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class CalendarSyncService {
  CalendarSyncService._();

  /// Opens the user's phone calendar (Google / Apple Calendar) with
  /// pre-filled title, dates, description, and alert reminder.
  static Future<bool> addEventToCalendar({
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? location,
  }) async {
    try {
      final effectiveEndDate = endDate ?? startDate.add(const Duration(hours: 1));

      // ISO-8601 Compact format for calendar URLs: YYYYMMDDTHHmmssZ
      final startStr = _formatCalendarUtc(startDate);
      final endStr = _formatCalendarUtc(effectiveEndDate);

      final fullTitle = title.startsWith('[Gixa]') ? title : '[Gixa] $title';
      final detailsText = "${description ?? ''}\n\nTracked via Gixa Medical Counselling Assistant.";
      final loc = location ?? "Online Counselling Portal";

      // 1. Google Calendar URL scheme (supported universally by Android & iOS browser/apps)
      final googleCalendarUrl = Uri.parse(
        'https://calendar.google.com/calendar/render?'
        'action=TEMPLATE'
        '&text=${Uri.encodeComponent(fullTitle)}'
        '&dates=$startStr/$endStr'
        '&details=${Uri.encodeComponent(detailsText)}'
        '&location=${Uri.encodeComponent(loc)}',
      );

      debugPrint("📅 Launching Calendar with URL: $googleCalendarUrl");

      final launched = await launchUrl(
        googleCalendarUrl,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        AppSnackbar.show(
          "Added to Calendar",
          "Opening calendar with event pre-filled...",
        );
        return true;
      } else {
        AppSnackbar.show(
          "Calendar Error",
          "Could not open device calendar application.",
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ Failed to add event to calendar: $e");
      AppSnackbar.show(
        "Calendar Error",
        "Unable to add event to calendar: $e",
      );
      return false;
    }
  }

  static String _formatCalendarUtc(DateTime dt) {
    final utc = dt.toUtc();
    return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(utc);
  }
}

