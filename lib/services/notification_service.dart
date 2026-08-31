import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:Gixa/services/notification_launch_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// 🔹 INIT
  static Future<void> init() async {
    debugPrint("🚀 INITIALIZING NOTIFICATION SERVICE");

    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,

      /// 🔥 CLICK HANDLER — works for foreground & background taps.
      /// For terminated-state (cold start) taps, [getInitialNotificationAppLaunchDetails]
      /// is checked separately below.
      onDidReceiveNotificationResponse: (details) async {
        debugPrint("👆 NOTIFICATION CLICKED");
        debugPrint("📦 PAYLOAD => ${details.payload}");

        final payload = details.payload ?? '';
        await handleNotificationTap(payload);
      },
    );

    // ── Handle tray tap when app was fully TERMINATED ───────────────────
    // This fires synchronously during init() — before any widget is built.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      final payload = launchDetails.notificationResponse!.payload ?? '';
      
      final lowerPayload = payload.toLowerCase();
      if (lowerPayload.startsWith('http://') || lowerPayload.startsWith('https://')) {
        // External URL — best effort: open after a short delay
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            await launchUrl(Uri.parse(payload),
                mode: LaunchMode.externalApplication);
          } catch (_) {}
        });
      } else {
        final targetRoute = _resolveTargetRoute(payload);
        NotificationLaunchService.setPendingRoute(targetRoute);
      }
    }

    await _createNotificationChannel();

    debugPrint("✅ NOTIFICATION SERVICE READY");
  }

  /// Handles tapping on a notification link/payload universally across the app.
  static Future<void> handleNotificationTap(String payload) async {
    final lowerPayload = payload.toLowerCase();

    // 1. External URL
    if (lowerPayload.startsWith('http://') || lowerPayload.startsWith('https://')) {
      try {
        final uri = Uri.parse(payload);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("❌ URL OPEN ERROR => $e");
      }
      return;
    }

    // 2. Resolve in-app route
    final targetRoute = _resolveTargetRoute(payload);

    try {
      if (Get.key.currentState != null) {
        Get.toNamed(targetRoute);
      } else {
        NotificationLaunchService.setPendingRoute(targetRoute);
      }
    } catch (_) {
      NotificationLaunchService.setPendingRoute(targetRoute);
    }
  }

  static String _resolveTargetRoute(String payload) {
    final lowerPayload = payload.toLowerCase();
    
    if (lowerPayload.contains('alert') ||
        lowerPayload == AppRoutes.alerts) {
      return AppRoutes.alerts;
    }
    
    // Navigate to choiceFilling (PredictionSheetScreen)
    if (lowerPayload.contains('choice filling') || 
        lowerPayload.contains('choice_filling') ||
        lowerPayload.contains('choice-filling') ||
        lowerPayload.contains('prediction') || 
        lowerPayload.contains('predication')) {
      return AppRoutes.choiceFilling;
    }
    
    if (lowerPayload == 'notification' ||
        lowerPayload == 'notifications' ||
        lowerPayload == AppRoutes.notifications ||
        lowerPayload == 'open_notifications' ||
        payload.isEmpty) {
      return AppRoutes.notifications;
    }
    
    if (payload.startsWith('/')) {
      return payload;
    }
    
    return AppRoutes.notifications;
  }

  /// 🔔 ANDROID 13+ PERMISSION
  static Future<void> requestPermission() async {
    debugPrint("🔔 REQUESTING NOTIFICATION PERMISSION");

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// 🔔 CREATE CHANNEL
  static Future<void> _createNotificationChannel() async {
    debugPrint("📢 CREATING NOTIFICATION CHANNEL");

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'gixa_alerts',

      'Gixa Alerts',

      description: 'Medical counselling alerts & updates',

      importance: Importance.high,

      sound: RawResourceAndroidNotificationSound('plan_expiry_sound'),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    debugPrint("✅ NOTIFICATION CHANNEL CREATED");
  }

  /// 🔥 GENERIC ALERT NOTIFICATION
  static Future<void> showAlertNotification({
    required int id,

    required String title,

    required String body,

    String? payload,
  }) async {
    try {
      debugPrint("🔥 SHOWING LOCAL NOTIFICATION");

      debugPrint("📰 TITLE => $title");

      debugPrint("🧾 BODY => $body");

      debugPrint("🔗 PAYLOAD => $payload");

      await _plugin.show(
        id,

        title,

        body,

        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gixa_alerts',

            'Gixa Alerts',

            importance: Importance.high,

            priority: Priority.high,

            playSound: true,

            enableVibration: true,
          ),
        ),

        payload: payload,
      );

      debugPrint("✅ LOCAL NOTIFICATION DISPLAYED");
    } catch (e, s) {
      debugPrint("❌ NOTIFICATION ERROR => $e");

      debugPrintStack(stackTrace: s);
    }
  }

  /// 🔊 TEST NOTIFICATION
  static Future<void> showTestNotification() async {
    debugPrint("🧪 TEST NOTIFICATION TRIGGERED");

    await showAlertNotification(
      id: 999,

      title: '🔔 Test Notification',

      body: 'Notifications are working properly 🎉',
    );
  }

  /// ⏰ PLAN EXPIRY SCHEDULE
  static Future<void> schedulePlanExpiryNotification({
    required String endDate,

    int daysBefore = 3,
  }) async {
    debugPrint("⏰ SCHEDULING PLAN EXPIRY NOTIFICATION");

    final expiryDate = DateTime.parse(endDate);

    final reminderDate = expiryDate.subtract(Duration(days: daysBefore));

    final scheduledTime = tz.TZDateTime.from(reminderDate, tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("⚠️ SCHEDULED TIME ALREADY PASSED");

      return;
    }

    await _plugin.zonedSchedule(
      1001,

      'Plan Expiry Alert ⏳',

      'Your subscription expires soon. Renew now!',

      scheduledTime,

      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gixa_alerts',

          'Gixa Alerts',

          importance: Importance.high,

          priority: Priority.high,
        ),
      ),

      androidAllowWhileIdle: true,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint("✅ PLAN EXPIRY NOTIFICATION SCHEDULED");
  }

  /// ❌ CANCEL
  static Future<void> cancelPlanExpiryNotification() async {
    debugPrint("❌ CANCELLING PLAN EXPIRY NOTIFICATION");

    await _plugin.cancel(1001);
  }
}
