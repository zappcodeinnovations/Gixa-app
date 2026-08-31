import 'package:Gixa/services/notification_service.dart';
import 'package:Gixa/services/notification_launch_service.dart';
import 'package:Gixa/services/logout_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:Gixa/controllers/analytics_controller.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use native config for Android, since firebase_options.dart has outdated credentials
  if (GetPlatform.isAndroid) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await GetStorage.init();

  await NotificationService.init();
  await NotificationService.requestPermission();

  Get.put(AnalyticsController(), permanent: true);

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // IMPORTANT: Gixa is a GetMaterialApp (see app.dart)
  // Do NOT replace with MaterialApp or navigation/snackbar will break!
  runApp(const Gixa());

  // Foreground message: show a local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? 'Gixa';
    final body = message.notification?.body ?? '';

    // Use the FCM data 'type' as payload so the local notification
    // click handler can route to the correct page (alerts vs notifications).
    // Fall back to link/url for external URLs, otherwise use the type.
    final link = message.data['link'] as String? ?? message.data['url'] as String? ?? '';
    final type = (message.data['type'] as String? ?? '').toLowerCase();
    final route = message.data['route'] as String? ?? '';
    
    // 🔥 Instant Logout
    if (type == 'force_logout' || type == 'logout') {
      SessionService.forceLogout(body.isNotEmpty ? body : 'Your account was logged in from another device.');
      return;
    }

    final payload = link.isNotEmpty ? link : (route.isNotEmpty ? route : (type.isNotEmpty ? type : 'notifications'));

    NotificationService.showAlertNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: payload,
    );
  });

  // When the app is opened from a notification while in BACKGROUND
  // (navigator is already ready, so we can navigate directly)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final route = NotificationLaunchService.resolveRouteFromData(message.data);
    try {
      Get.toNamed(route);
    } catch (_) {
      // Navigator may not be ready in rare edge cases; store as pending
      NotificationLaunchService.setPendingRoute(route);
    }
  });

  // When the app is COLD-STARTED (terminated) via a notification tap
  // The navigator is NOT ready here yet — store the route and let
  // AppStartController pick it up after the splash completes.
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      final route = NotificationLaunchService.resolveRouteFromData(message.data);
      NotificationLaunchService.setPendingRoute(route);
    }
  });
}

/// Background message handler must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final title = message.notification?.title ?? 'Gixa';
  final body = message.notification?.body ?? '';

  // Same payload logic as foreground handler
  final link = message.data['link'] as String? ?? message.data['url'] as String? ?? '';
  final type = (message.data['type'] as String? ?? '').toLowerCase();
  final route = message.data['route'] as String? ?? '';
  
  if (type == 'force_logout' || type == 'logout') {
    await GetStorage.init();
    final box = GetStorage();
    await box.remove('phone_verified');
    await box.remove('registration_completed');
    await box.remove('user_id');
    
    // Cannot safely use SessionService in background due to Get.offAllNamed routing
    // Token will be invalid anyway, and API will return 401 if they somehow had valid token
  }

  final payload = link.isNotEmpty ? link : (route.isNotEmpty ? route : (type.isNotEmpty ? type : 'notifications'));

  try {
    await NotificationService.init();
  } catch (_) {}

  await NotificationService.showAlertNotification(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    payload: payload,
  );
}
