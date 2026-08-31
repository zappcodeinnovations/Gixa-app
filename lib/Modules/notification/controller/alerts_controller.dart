import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';

import 'package:Gixa/Modules/notification/model/student_notification_model.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';
import 'package:Gixa/network/app_exception.dart';
import 'package:Gixa/services/appnotification_services.dart';
import 'package:Gixa/services/notification_service.dart';
import 'package:Gixa/services/notification_action_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AlertsController extends GetxController {
  final alerts = <StudentNotification>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final hasLoaded = false.obs;
  final alertCount = 0.obs;

  final GetStorage _box = GetStorage();
  final Set<int> _readAlertIds = <int>{};

  /// SELECTED ALERT IDS
  final selectedAlerts = <int>[].obs; // Pagination state
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasNext = false.obs;
  final isLoadingMore = false.obs;

  bool _refreshQueued = false;
  bool _hasProcessedInitialFetch = false;
  final Set<int> _sessionNotifiedAlertIds = <int>{};
  final Set<int> _shownAlertIds = <int>{};

  final NotificationApiService _service = NotificationApiService();

  Timer? _refreshTimer;

  bool get hasAlerts => alertCount.value > 0;

  bool isSelected(int id) => selectedAlerts.contains(id);

  bool get hasSelection => selectedAlerts.isNotEmpty;

  String get alertBadgeLabel =>
      alertCount.value > 99 ? '99+' : alertCount.value.toString();

  @override
  void onInit() {
    super.onInit();
    _restoreReadAlerts();
    fetchAlerts();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchAlerts();
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchAlerts({
    bool forceRefresh = false,
    bool showErrorSnackbar = false,
    int page = 1,
  }) async {
    if (isLoading.value) {
      _refreshQueued = true;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.fetchNotifications(page: page);

      final previousAlerts = List<StudentNotification>.from(alerts);
      final previousIds = previousAlerts.map((e) => e.id).toSet();

      // Replace alerts when refreshing, append when loading more
      if (page == 1) {
        alerts.assignAll(response.results);
      } else {
        alerts.addAll(response.results);
      }
      
      // Update local read states based on stored IDs
      for (int i = 0; i < alerts.length; i++) {
        if (_readAlertIds.contains(alerts[i].id)) {
          final n = alerts[i];
          alerts[i] = StudentNotification(
            id: n.id, source: n.source, sourceUrl: n.sourceUrl, title: n.title,
            body: n.body, link: n.link, attachment: n.attachment, createdAt: n.createdAt,
            isRead: true,
          );
        }
      }

      _updateAlertCount();
      hasLoaded.value = true;

      // Update pagination state
      currentPage.value = response.page;
      totalPages.value = response.totalPages;
      hasNext.value = response.hasNext;

      debugPrint(
        '🔔 ALERTS FETCH => count=${response.results.length}, initial=$_hasProcessedInitialFetch',
      );

      await _showNewAlertNotifications(
        previousIds: previousIds,
        latestAlerts: response.results,
        fallbackAlerts: previousAlerts,
      );
    } on AppException catch (e) {
      errorMessage.value = e.message;
      if (showErrorSnackbar) {
        AppSnackbar.show('Error', e.message);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load alerts';
      if (showErrorSnackbar) {
        AppSnackbar.show('Error', errorMessage.value);
      }
    } finally {
      isLoading.value = false;

      if (_refreshQueued) {
        _refreshQueued = false;
        unawaited(
          fetchAlerts(forceRefresh: true, showErrorSnackbar: showErrorSnackbar),
        );
      }
    }
  }

  void _updateAlertCount() {
    alertCount.value = alerts.where((alert) => !alert.isRead).length;
    _updateDeviceBadge(alertCount.value);
  }

  Future<void> refreshAlerts() async {
    await fetchAlerts(forceRefresh: true, showErrorSnackbar: true, page: 1);
  }

  Future<void> loadMoreAlerts() async {
    if (!hasNext.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      final nextPage = currentPage.value + 1;
      final response = await _service.fetchNotifications(page: nextPage);

      // Append new alerts to existing list
      alerts.addAll(response.results);

      // Update pagination state
      currentPage.value = response.page;
      totalPages.value = response.totalPages;
      hasNext.value = response.hasNext;

      debugPrint(
        '🔔 LOAD MORE => page=$nextPage, loaded=${response.results.length}',
      );
    } on AppException catch (e) {
      debugPrint('🔔 LOAD MORE ERROR => ${e.message}');
    } catch (e) {
      debugPrint('🔔 LOAD MORE ERROR => $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void markAsRead(int id) async {
    // Optimistic UI update
    final index = alerts.indexWhere((n) => n.id == id);
    if (index != -1) {
      final n = alerts[index];
      alerts[index] = StudentNotification(
        id: n.id, source: n.source, sourceUrl: n.sourceUrl, title: n.title,
        body: n.body, link: n.link, attachment: n.attachment, createdAt: n.createdAt,
        isRead: true,
      );
    }
    
    _readAlertIds.add(id);
    _saveReadAlerts();
    _updateAlertCount();
    alerts.refresh();

    try {
      await NotificationActionService.markAsRead(id);
    } catch (e) {
      debugPrint('MARK AS READ ERROR => $e');
    }
  }

  void markSelectedAsRead() async {
    // Optimistic UI update
    for (final id in selectedAlerts) {
      final index = alerts.indexWhere((n) => n.id == id);
      if (index != -1) {
        final n = alerts[index];
        alerts[index] = StudentNotification(
          id: n.id, source: n.source, sourceUrl: n.sourceUrl, title: n.title,
          body: n.body, link: n.link, attachment: n.attachment, createdAt: n.createdAt,
          isRead: true,
        );
      }
      _readAlertIds.add(id);
    }
    
    _saveReadAlerts();
    _updateAlertCount();
    alerts.refresh();

    final previousSelection = List<int>.from(selectedAlerts);
    clearSelection();

    try {
      for (final id in previousSelection) {
        await NotificationActionService.markAsRead(id);
      }
    } catch (e) {
      debugPrint('MARK MULTIPLE READ ERROR => $e');
    }
  }

  void toggleSelection(int id) {
    if (selectedAlerts.contains(id)) {
      selectedAlerts.remove(id);
    } else {
      selectedAlerts.add(id);
    }

    selectedAlerts.refresh();
  }

  void selectAllAlerts() {
    selectedAlerts.assignAll(alerts.map((e) => e.id).toList());
  }

  void clearSelection() {
    selectedAlerts.clear();
  }



  Future<void> _showNewAlertNotifications({
    required Set<int> previousIds,
    required List<StudentNotification> latestAlerts,
    required List<StudentNotification> fallbackAlerts,
  }) async {
    final latestAlert = _pickLatestAlert(latestAlerts);

    if (!_hasProcessedInitialFetch) {
      _hasProcessedInitialFetch = true;

      _shownAlertIds.addAll(latestAlerts.map((alert) => alert.id).where((id) => id != 0));
      return;
    }

    final newAlerts = latestAlerts
        .where((alert) => alert.id != 0 && !previousIds.contains(alert.id))
        .toList();

    if (newAlerts.isEmpty && latestAlert != null) {
      if (_sessionNotifiedAlertIds.add(latestAlert.id) &&
          _shownAlertIds.add(latestAlert.id)) {
        debugPrint('🔔 ALERT POPUP => fallback latest id=${latestAlert.id}');
        await NotificationService.showAlertNotification(
          id: latestAlert.id,
          title: latestAlert.title.isNotEmpty ? latestAlert.title : 'New Alert',
          body: latestAlert.bodyText,
          payload: latestAlert.link.isNotEmpty
              ? latestAlert.link
              : (latestAlert.sourceUrl.isNotEmpty ? latestAlert.sourceUrl : 'alerts'),
        );
      }

      _shownAlertIds.addAll([...latestAlerts, ...fallbackAlerts].map((alert) => alert.id).where((id) => id != 0));
      return;
    }

    if (newAlerts.isEmpty) {
      return;
    }

    // Show oldest first so notifications arrive in a natural order.
    newAlerts.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    for (final alert in newAlerts) {
      if (!_sessionNotifiedAlertIds.add(alert.id) ||
          !_shownAlertIds.add(alert.id)) {
        debugPrint('🔔 ALERT SKIP => already shown id=${alert.id}');
        continue;
      }

      debugPrint('🔔 ALERT POPUP => new id=${alert.id}');
      await NotificationService.showAlertNotification(
        id: alert.id,
        title: alert.title.isNotEmpty ? alert.title : 'New Alert',
        body: alert.bodyText,
        payload: alert.link.isNotEmpty ? alert.link : (alert.sourceUrl.isNotEmpty ? alert.sourceUrl : 'alerts'),
      );
    }

    _shownAlertIds.addAll([...latestAlerts, ...fallbackAlerts].map((alert) => alert.id).where((id) => id != 0));
  }

  StudentNotification? _pickLatestAlert(List<StudentNotification> alerts) {
    if (alerts.isEmpty) {
      return null;
    }

    final sortedAlerts = List<StudentNotification>.from(alerts)
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return sortedAlerts.first;
  }



  void _updateDeviceBadge(int count) {
    if (count > 0) {
      FlutterAppBadgeControl.updateBadgeCount(count);
    } else {
      FlutterAppBadgeControl.removeBadge();
    }
  }

  void _restoreReadAlerts() {
    final raw = _box.read('read_alert_ids');

    if (raw is List) {
      _readAlertIds.addAll(
        raw.map((e) => int.tryParse(e.toString())).whereType<int>(),
      );
    }
  }

  void _saveReadAlerts() {
    _box.write('read_alert_ids', _readAlertIds.toList());
  }
}
