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

  /// Store the route that should be opened after the splash/startup sequence.
  static void setPendingRoute(String route) {
    _pendingRoute = route;
  }

  /// Consume and return the pending route (clears it after reading).
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Whether a pending notification route is waiting to be handled.
  static bool get hasPendingRoute => _pendingRoute != null;

  /// Resolve the correct in-app route from an FCM [RemoteMessage]'s data map.
  ///
  /// Convention used by the backend:
  ///   - `data['type'] == 'alert'`  → open /alerts
  ///   - `data['type'] == 'notification'` (or anything else) → open /notifications
  ///   - `data['route']` can override with an explicit route string
  static String resolveRouteFromData(Map<String, dynamic> data) {
    // Explicit route override wins
    final explicitRoute = data['route'] as String?;
    if (explicitRoute != null && explicitRoute.startsWith('/')) {
      return explicitRoute;
    }

    final type = (data['type'] as String? ?? '').toLowerCase();
    final routeLower = (explicitRoute ?? '').toLowerCase();

    if (type.contains('alert') || routeLower.contains('alert')) {
      return '/alerts';
    }

    // Default: general notifications page
    return '/notifications';
  }
}
