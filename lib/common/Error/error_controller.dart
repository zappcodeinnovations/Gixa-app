import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:Gixa/common/Error/network_reachability.dart';

class GlobalErrorController extends GetxController {
  bool hasError = false;
  bool isNetworkError = false;
  String errorMessage = "";

  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  bool _appReady = false;

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        _appReady = true;
        _listenToConnectionChanges();
        refreshConnectionStatus();
      }
    });
  }

  void _listenToConnectionChanges() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (!_appReady || isClosed) return;
      _handleConnectivityResult(result);
    });
  }

  Future<void> refreshConnectionStatus() async {
    if (!_appReady || isClosed) return;

    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityResult(result);
    } catch (e) {
      // ignore errors
    }
  }

  void _handleConnectivityResult(dynamic result) {
    if (isClosed) return;

    bool hasNoConnection = false;
    if (result is List) {
      hasNoConnection = result.contains(ConnectivityResult.none) || result.isEmpty;
    } else {
      hasNoConnection = result == ConnectivityResult.none;
    }

    if (hasNoConnection) {
      _safeUpdate(() {
        hasError = true;
        isNetworkError = true;
        errorMessage = "No Internet Connection";
      });
    } else {
      _safeUpdate(() {
        hasError = false;
        isNetworkError = false;
        errorMessage = "";
      });
    }
  }

  void showNetworkError({String? message}) {
    if (isClosed) return;

    _safeUpdate(() {
      hasError = true;
      isNetworkError = true;
      errorMessage = message ?? "No Internet Connection";
    });
  }

  void showServerError() {
    if (isClosed) return;

    _safeUpdate(() {
      hasError = true;
      isNetworkError = false;
      errorMessage = "Server error. Please try again later.";
    });
  }

  void hideError() {
    if (isClosed) return;

    _safeUpdate(() {
      hasError = false;
      isNetworkError = false;
      errorMessage = "";
    });
  }

  void _safeUpdate(VoidCallback fn) {
    if (!isClosed) {
      fn();
      update();
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }
}
