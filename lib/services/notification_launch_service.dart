import 'package:Gixa/Modules/Documents/controller/view_document_controller.dart';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:get/get.dart';

/// A lightweight singleton that stores the intended navigation target
/// when the app is launched (cold-started) from a notification tap.
///
/// Because GetX's navigator is not available during [main()] initialisation
/// we cannot call [Get.toNamed] immediately. Instead, we stash the route here
/// and let [AppStartController.decideNextRoute] pick it up once the navigator
/// is fully ready.
class NotificationLaunchService {
  NotificationLaunchService._();

  static String? _pendingRoute;
  static String? _pendingType;

  /// Store the route that should be opened after the splash/startup sequence.
  static void setPendingRoute(String route, {String? type}) {
    _pendingRoute = route;
    _pendingType = type;
  }

  /// Consume and return the pending route (clears it after reading).
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    final type = _pendingType;
    _pendingRoute = null;
    _pendingType = null;

    if (type != null && type.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 600), () {
        executePostNotificationAction(type);
      });
    }

    return route;
  }

  /// Whether a pending notification route is waiting to be handled.
  static bool get hasPendingRoute => _pendingRoute != null;

  /// Resolve the correct in-app route from an FCM [RemoteMessage]'s data map.
  ///
  /// Supported types:
  ///   - `DOCUMENT_VERIFIED`      → AppRoutes.updateDocs (/update-docs)
  ///   - `DOCUMENT_UNVERIFIED`    → AppRoutes.updateDocs (/update-docs)
  ///   - `APPLICATION_STATUS_UPDATE` → AppRoutes.choiceFilling (/choice-filling)
  ///   - `alert`                  → AppRoutes.alerts (/alerts)
  ///   - Default                  → AppRoutes.notifications (/notifications)
  static String resolveRouteFromData(Map<String, dynamic> data) {
    // Explicit route override wins
    final explicitRoute = data['route'] as String?;
    if (explicitRoute != null && explicitRoute.startsWith('/')) {
      return explicitRoute;
    }

    final type = (data['type'] as String? ?? '').trim().toUpperCase();
    final routeLower = (explicitRoute ?? '').toLowerCase();

    // 1. Document Verified / Unverified -> My Documents screen
    if (type == 'DOCUMENT_VERIFIED' || type == 'DOCUMENT_UNVERIFIED') {
      return AppRoutes.updateDocs;
    }

    // 2. Application Status Update -> Counseling Roadmap / Admission Guide
    if (type == 'APPLICATION_STATUS_UPDATE') {
      return AppRoutes.choiceFilling;
    }

    if (type.contains('ALERT') || routeLower.contains('alert')) {
      return AppRoutes.alerts;
    }

    // Default: general notifications page
    return AppRoutes.notifications;
  }

  /// Refreshes controllers or syncs state based on the notification type
  static void executePostNotificationAction(String type, [Map<String, dynamic>? data]) {
    final upperType = type.trim().toUpperCase();

    if (upperType == 'DOCUMENT_VERIFIED' || upperType == 'DOCUMENT_UNVERIFIED') {
      try {
        if (Get.isRegistered<StudentDocumentsController>()) {
          Get.find<StudentDocumentsController>().refreshDocuments();
        }
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().fetchProfile(force: true);
        }
      } catch (e) {
        // Safe catch
      }
    } else if (upperType == 'APPLICATION_STATUS_UPDATE') {
      try {
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().fetchProfile(force: true);
        }
      } catch (e) {
        // Safe catch
      }
    }
  }
}
