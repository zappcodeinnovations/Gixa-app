import 'dart:async';
import 'dart:convert';
import 'package:Gixa/Modules/payment/controller/payment_controller.dart';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/subscription/controller/subsciption_history_controller.dart';
import 'package:Gixa/Modules/subscription/model/create_order_model.dart';
import 'package:Gixa/Modules/subscription/model/subscription_history_model.dart'
    as history_models;
import 'package:Gixa/Modules/subscription/model/subscription_plan.dart'
    as plan_models;
import 'package:Gixa/Modules/subscription/model/subscription_purchase_model.dart';
import 'package:Gixa/Modules/subscription/model/subscription_state_model.dart';
import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/app_exception.dart';
import 'package:Gixa/services/subscription_plan_services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';
import 'package:Gixa/services/app_verification_controller.dart';
import 'package:Gixa/Modules/payment/view/payment_success_dialog.dart';
import 'package:Gixa/Modules/payment/view/payment_fail_dialog.dart';

class SubscriptionController extends GetxController {
  final plans = <plan_models.SubscriptionPlan>[].obs;
  final activePlan = Rxn<plan_models.SubscriptionPlan>();
  final isLoading = false.obs;
  final isCreatingOrder = false.obs;
  final previewMap = <int, SubscriptionPurchaseData>{}.obs;
  final couponErrorMap = <int, String>{}.obs;
  final applyingCouponMap = <int, bool>{}.obs;
  final selectedStates = <int>[].obs;
  final selectedCourses = <int>[].obs;
  final lockedCourses = <int>[].obs; // Courses from profile that cannot be unselected

  /// Regular subscription plans
  List<plan_models.SubscriptionPlan> get regularPlans =>
      plans.where((p) => p.isAddon != true).toList();

  /// Add-on plans
  List<plan_models.SubscriptionPlan> get addonPlans =>
      plans.where((p) => p.isAddon == true).toList();

  /// Check if addon plans available
  bool get hasAddonPlans => addonPlans.isNotEmpty;

  final GetStorage _box = GetStorage();
  late final PaymentController _paymentController;
  late final SubscriptionHistoryController _historyController;
  late final Razorpay _razorpay;

  Future<void>? _plansFuture;
  Future<void>? _activePlanFuture;

  CreateOrderData? _currentOrder;

  String _userFeaturesKey(int userId) => 'user_features_$userId';
  String _activePlanKey(int userId) => 'active_plan_snapshot_$userId';
  String get _userIdKey => 'user_id';

  bool get isSubscribed =>
      AppVerificationController.to.hideSubscriptionUi ||
      activePlan.value != null;
  String get activePlanName => activePlan.value?.planName ?? "Free Plan";

  final availableStates = <StateItem>[].obs;
  final availableCourses = <AvailableCourse>[].obs;
  final isStateLoading = false.obs;
  @override
  void onInit() {
    super.onInit();

    _paymentController = Get.isRegistered<PaymentController>()
        ? Get.find<PaymentController>()
        : Get.put(PaymentController());

    _historyController = Get.isRegistered<SubscriptionHistoryController>()
        ? Get.find<SubscriptionHistoryController>()
        : Get.put(SubscriptionHistoryController());

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);

    _restoreActivePlanFromStorage();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  void clearUserSubscriptionData() {
    final userId = _readUserIdFromStorage();
    if (userId != null) {
      _box.remove(_userFeaturesKey(userId));
      _box.remove(_activePlanKey(userId));
    }

    _box.remove(_userIdKey);
    activePlan.value = null;
    plans.clear();
    previewMap.clear();
    couponErrorMap.clear();
    _plansFuture = null;
    _activePlanFuture = null;

    ApiClient.invalidateGetCache(
      endpointPrefixes: const [
        '/subscription-plans/',
        '/api/subscriptions/user/',
        '/api/payment-credentials/',
      ],
    );
  }

  final purchasedCourseNames = <String>[].obs;

  Future<void> loadStates() async {
    try {
      isStateLoading.value = true;
      final data = await SubscriptionApi.getStatesWithoutSubscription();
      
      final profileController = Get.isRegistered<ProfileController>() 
          ? Get.find<ProfileController>() 
          : Get.put(ProfileController());
          
      final filteredCourses = data.availableCourses.where((course) {
        final isCourseUG = profileController.isCourseUG(course.id);
        return profileController.isUGUser == isCourseUG;
      }).toList();

      availableStates.assignAll(data.availableStates);
      availableCourses.assignAll(filteredCourses);
      selectedStates.clear();
      final lockedIds = data.selectedCourses
          .map((e) => e.id != -1 ? e.id : e.courseId)
          .where((id) => id != -1)
          .toList();

      final profileCourse = profileController.profile.value?.course?.trim().toUpperCase();
      if (profileCourse == 'MBBS') {
        final bdsCourse = filteredCourses.firstWhereOrNull((c) => c.courseName.toUpperCase() == 'BDS');
        if (bdsCourse != null) {
          final bdsId = bdsCourse.id != -1 ? bdsCourse.id : bdsCourse.courseId;
          if (bdsId != -1 && !lockedIds.contains(bdsId)) {
            lockedIds.add(bdsId);
          }
        }
      }

      lockedCourses.assignAll(lockedIds);
      selectedCourses.assignAll(lockedIds);
      purchasedCourseNames.assignAll(data.selectedCourses.map((e) => e.courseName).toList());
    } catch (e) {
      print("❌ ERROR: $e");
    } finally {
      isStateLoading.value = false;
    }
  }

  /// =======================================================
  /// ACCESSIBLE STATES FOR PREDICTION
  /// =======================================================

  List<String> getAccessiblePredictionStates({
    required String primaryState,
    required List<String> allStates,
  }) {
    final plan = activePlan.value;

    /// FREE USER
    if (plan == null) {
      return [primaryState];
    }

    /// ADDON PLAN = ALL STATES
    if (plan.isAddon == true || _historyController.hasActiveAddonPlan()) {
      return allStates;
    }

    /// REGULAR PLAN
    final selectedStateNames = availableStates
        .where(
          (state) =>
              selectedStates.contains(int.tryParse(state.id.toString()) ?? -1),
        )
        .map((e) => e.name ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final finalStates = <String>[
      primaryState,
      ...selectedStateNames,
    ].toSet().toList();

    return finalStates;
  }

  Future<void> fetchPlans({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      final fetchedPlans = await SubscriptionApi.getPlans(
        forceRefresh: forceRefresh,
      );
      
      fetchedPlans.sort((a, b) {
        final priceA = double.tryParse(a.amount) ?? 0.0;
        final priceB = double.tryParse(b.amount) ?? 0.0;
        return priceA.compareTo(priceB);
      });

      plans.assignAll(fetchedPlans);

      final currentPlanCode = activePlan.value?.planCode;
      if (currentPlanCode != null && currentPlanCode.isNotEmpty) {
        setActivePlanByCode(currentPlanCode);
      }
    } catch (e) {
      print('[SubscriptionController] Error fetching plans: $e');
      // Supressed global snackbar here to prevent disruptive errors on app resume/start
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> ensurePlanCatalogLoaded({bool forceRefresh = false}) async {
    if (!forceRefresh && plans.isNotEmpty) return;

    final inFlight = _plansFuture;
    if (!forceRefresh && inFlight != null) return inFlight;

    final future = fetchPlans(forceRefresh: forceRefresh);
    _plansFuture = future;

    try {
      await future;
    } finally {
      if (identical(_plansFuture, future)) _plansFuture = null;
    }
  }

  bool setActivePlanByCode(String planCode) {
    final normalizedInput = _normalizeText(planCode);

    for (final plan in plans) {
      final code = _normalizeText(plan.planCode);
      final name = _normalizeText(plan.planName);

      if (code == normalizedInput || name == normalizedInput) {
        activePlan.value = plan;
        final userId = _readUserIdFromStorage();
        if (userId != null) _cacheActivePlanForUser(userId);
        return true;
      }
    }

    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APPLY COUPON — fixed to handle 400 responses from ApiClient correctly
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> applyCoupon({
    required int planId,
    required String couponCode,
  }) async {
    /// Prevent multiple clicks
    if (applyingCouponMap[planId] == true) return;

    /// Empty coupon validation
    if (couponCode.trim().isEmpty) {
      couponErrorMap[planId] = 'Please enter coupon code';

      couponErrorMap.refresh();

      AppSnackbar.show('Coupon Required', 'Please enter coupon code');

      return;
    }

    /// START LOADING
    applyingCouponMap[planId] = true;

    applyingCouponMap.refresh();

    /// Clear previous states
    couponErrorMap[planId] = '';

    previewMap.remove(planId);

    couponErrorMap.refresh();
    previewMap.refresh();

    try {
      final res = await SubscriptionApi.purchaseSubscription(
        planId: planId,
        couponCode: couponCode.trim(),
        stateIds: selectedStates.toList(),
        courseIds: selectedCourses.toList(),
      );

      print("COUPON RESPONSE => ${res.status}");

      /// SUCCESS
      if (res.status == true && res.data != null) {
        previewMap[planId] = res.data!;

        couponErrorMap[planId] = '';

        previewMap.refresh();
        couponErrorMap.refresh();

        AppSnackbar.show('Success', 'Coupon applied successfully');
      }
      /// INVALID COUPON
      else {
        final msg = res.message.toString().trim().isNotEmpty
            ? res.message.toString()
            : 'Invalid coupon code';

        couponErrorMap[planId] = msg;

        previewMap.remove(planId);

        couponErrorMap.refresh();
        previewMap.refresh();

        AppSnackbar.show('Invalid Coupon', msg);
      }
    }
    /// API / NETWORK ERROR
    catch (e) {
      print("COUPON ERROR => $e");

      String msg = 'Something went wrong';

      if (e.toString().contains('SocketException')) {
        msg = 'No internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        msg = 'Request timeout';
      } else if (e.toString().trim().isNotEmpty) {
        msg = e.toString();
      }

      couponErrorMap[planId] = msg;

      previewMap.remove(planId);

      couponErrorMap.refresh();
      previewMap.refresh();

      AppSnackbar.show('Coupon Error', msg);
    }
    /// ALWAYS STOP LOADING
    finally {
      applyingCouponMap[planId] = false;

      applyingCouponMap.refresh();

      print("LOADING STOPPED => $planId");
    }
  }

  void clearCoupon(int planId) {
    previewMap.remove(planId);
    couponErrorMap.remove(planId);
    previewMap.refresh();
    couponErrorMap.refresh();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COURSE/STATE PREVIEW UPDATE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> updateCourseSelectionPrice(int planId) async {
    try {
      final preview = previewMap[planId];
      final res = await SubscriptionApi.purchaseSubscription(
        planId: planId,
        couponCode: preview?.couponApplied,
        stateIds: selectedStates.toList(),
        courseIds: selectedCourses.toList(),
      );

      if (res.status == true && res.data != null) {
        previewMap[planId] = res.data!;
        previewMap.refresh();
      }
    } catch (e) {
      print("Failed to update course selection price: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REST OF CONTROLLER — unchanged
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> createOrderAndPay(int planId, {bool isAddonOnly = false}) async {
    if (isCreatingOrder.value) return false;

    isCreatingOrder.value = true;

    try {
      await ensurePlanCatalogLoaded();
      await _historyController.ensureLoaded();

      final hasActiveAddon = _historyController.hasActiveAddonPlan();
      final hasBasePlan = _historyController.isPlanActive(planId);
      
      if (!isAddonOnly && (hasActiveAddon || hasBasePlan)) {
        AppSnackbar.show(
          'Subscription Active',
          'You already have an active subscription for this plan.',
        );
        return false;
      }

      final plan = plans.firstWhere((p) => p.id == planId);
      final preview = previewMap[planId];

      int baseAmount = _parseAmount(plan.amount);
      int finalAmount = baseAmount;
      int extraDays = 0;
      String? appliedCouponCode = preview?.couponApplied;

      if (isAddonOnly) {
        int coursesAmount = 0;
        for (final courseId in selectedCourses) {
          if (lockedCourses.contains(courseId)) continue;
          final course = availableCourses.firstWhereOrNull((c) => (c.id != -1 ? c.id : c.courseId) == courseId);
          if (course != null) {
            coursesAmount += course.amount.round();
          }
        }
        baseAmount = coursesAmount;
        finalAmount = coursesAmount;
      } else {
        // Fetch fresh preview to include selected states and courses
        final freshPreviewRes = await SubscriptionApi.purchaseSubscription(
          planId: planId,
          couponCode: preview?.couponApplied,
          stateIds: selectedStates.toList(),
          courseIds: selectedCourses.toList(),
        );

        if (freshPreviewRes.status == true && freshPreviewRes.data != null) {
          finalAmount = _parseAmount(freshPreviewRes.data!.finalPayableAmount);
          extraDays = freshPreviewRes.data!.extraDays;
          appliedCouponCode = freshPreviewRes.data!.couponApplied;
        } else {
          finalAmount = preview != null
              ? _parseAmount(preview.finalPayableAmount)
              : baseAmount;
          extraDays = preview?.extraDays ?? 0;
        }
      }

      final orderRes = await SubscriptionApi.createOrder(
        planId: planId,
        baseAmount: baseAmount,
        finalAmount: finalAmount,
        couponCode: appliedCouponCode,
        extraDays: extraDays,
        stateIds: selectedStates.toList(),
        courseIds: selectedCourses.toList(),
      );

      _currentOrder = orderRes.data;
      return await _openRazorpay(finalAmount);
    } on AppException catch (e, stackTrace) {
      print(
        '[SubscriptionController] createOrderAndPay AppException: ${e.message}',
      );
      print(stackTrace);
      AppSnackbar.show('Error', e.message);
      return false;
    } catch (e, stackTrace) {
      print('[SubscriptionController] createOrderAndPay unexpected error: $e');
      print(stackTrace);
      AppSnackbar.show('Error', 'Unable to create order. $e');
      return false;
    } finally {
      isCreatingOrder.value = false;
    }
  }

  Future<bool> _openRazorpay(int finalAmount) async {
    var key = _paymentController.razorpayKey;

    if (key.isEmpty) {
      await _paymentController.loadCredentials();
      key = _paymentController.razorpayKey;
    }

    if (key.isEmpty) {
      AppSnackbar.show(
        'Payment Error',
        'Payment service not available. Please try later.',
      );
      return false;
    }

    _razorpay.open({
      'key': key,
      'order_id': _currentOrder!.razorpayOrderId,
      'amount': finalAmount * 100,
      'name': 'Gixa',
      'description': 'Subscription Purchase',
    });
    return true;
  }

  bool isFeatureUnlocked(String featureCode) {
    if (AppVerificationController.to.hideSubscriptionUi) return true;

    final plan = activePlan.value;
    if (plan == null) return false;
    if (plan.isAddon == true || _historyController.hasActiveAddonPlan())
      return true;

    return plan.features.any(
      (feature) =>
          feature.featureCode.trim().toLowerCase() ==
              featureCode.trim().toLowerCase() &&
          feature.isEnabled,
    );
  }

  bool hasFeature(String featureName) {
    if (AppVerificationController.to.hideSubscriptionUi) return true;

    final plan = activePlan.value;
    if (plan == null) return false;

    if (plan.isAddon == true || _historyController.hasActiveAddonPlan())
      return true;

    final normalizedRequired = _normalizeFeatureText(featureName);
    return plan.features.any((feature) {
      final normalizedAvailable = _normalizeFeatureText(feature.featureTitle);
      return (normalizedAvailable == normalizedRequired ||
              normalizedAvailable.contains(normalizedRequired) ||
              normalizedRequired.contains(normalizedAvailable)) &&
          feature.isEnabled;
    });
  }

  Future<void> loadActivePlanFromHistory(
    int userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final history = await SubscriptionApi.getSubscriptionHistory(
        userId: userId,
        forceRefresh: forceRefresh,
      );

      history_models.SubscriptionHistory? activeHistory;
      for (final item in history) {
        if (item.isActive) {
          activeHistory = item;
          break;
        }
      }

      if (activeHistory == null) {
        activePlan.value = null;
        _clearCachedActivePlan(userId);
        return;
      }

      await ensurePlanCatalogLoaded(forceRefresh: forceRefresh);

      final didSet = setActivePlanByCode(activeHistory.plan.planCode);
      if (!didSet) {
        activePlan.value = _subscriptionPlanFromHistory(activeHistory.plan);
      }

      _cacheActivePlanForUser(userId);
    } catch (e) {
      print("Failed to load active plan from history: $e");
    }
  }

  Future<void> ensureActivePlanReady({bool forceRefresh = false}) async {
    if (!forceRefresh && activePlan.value != null) return;

    final userId = _resolveCurrentUserId();
    if (userId == null) return;

    final inFlight = _activePlanFuture;
    if (!forceRefresh && inFlight != null) return inFlight;

    final future = loadActivePlanFromHistory(
      userId,
      forceRefresh: forceRefresh,
    );
    _activePlanFuture = future;

    try {
      await future;
    } finally {
      if (identical(_activePlanFuture, future)) _activePlanFuture = null;
    }
  }

  int getStateLimit(plan_models.SubscriptionPlan plan) {
    final feature = plan.features.firstWhereOrNull(
      (f) =>
          f.featureCode.toLowerCase().contains("state") &&
          f.featureLimit != null,
    );

    if (feature == null || feature.featureLimit == null) {
      throw Exception(
        "State limit not provided by backend for plan: ${plan.planName}",
      );
    }

    return feature.featureLimit!;
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse res) async {
    try {
      print("💰 PAYMENT SUCCESS TRIGGERED");

      final verifyRes = await SubscriptionApi.verifyPayment(
        razorpayOrderId: res.orderId!,
        razorpayPaymentId: res.paymentId!,
        razorpaySignature: res.signature!,
      );

      if (!verifyRes.status) {
        AppSnackbar.show("Error", "Payment verification failed");
        return;
      }

      final subscriptionId =
          verifyRes.subscriptionId ?? verifyRes.data?.subscriptionId;

      if (subscriptionId == null) {
        AppSnackbar.show("Error", "Subscription ID missing");
        return;
      }

      if (selectedStates.isNotEmpty || selectedCourses.isNotEmpty) {
        await SubscriptionApi.saveSubscriptionStates(
          subscriptionId: subscriptionId,
          stateIds: selectedStates,
          courseIds: selectedCourses,
        );
      }

      selectedStates.clear();
      selectedCourses.clear();

      final userId = _resolveCurrentUserId();
      if (userId != null) {
        await _historyController.ensureLoaded(forceRefresh: true);
        await loadActivePlanFromHistory(userId, forceRefresh: true);
      }

      Get.dialog(const PaymentSuccessDialog(), barrierDismissible: false);
    } catch (e, stack) {
      print('[_onPaymentSuccess] error: $e\n$stack');
      AppSnackbar.show("Error", e.toString());
    }
  }

  void _onPaymentError(PaymentFailureResponse res) {
    selectedStates.clear();
    selectedCourses.clear();

    String message;

    switch (res.code) {
      case Razorpay.PAYMENT_CANCELLED:
        message = 'Payment cancelled by user';
        break;

      case Razorpay.NETWORK_ERROR:
        message = 'Network issue while processing payment';
        break;

      case Razorpay.INVALID_OPTIONS:
        message = 'Unable to start payment. Please try again';
        break;

      default:
        final raw = (res.message ?? '').trim().toLowerCase();

        if (raw.isEmpty || raw == 'undefined' || raw == 'null') {
          message = 'Payment failed. Please try again';
        } else {
          message = res.message!;
        }
    }

    Get.dialog(PaymentFailDialog(message: message), barrierDismissible: false);
  }

  Future<void> _refreshActivePlanAfterPayment(String verifiedPlanCode) async {
    await ensurePlanCatalogLoaded(forceRefresh: true);

    final userId = _readUserIdFromStorage();
    if (userId != null) {
      await _historyController.ensureLoaded(forceRefresh: true);
      await loadActivePlanFromHistory(userId, forceRefresh: true);
    }

    if (activePlan.value == null && plans.isNotEmpty) {
      final didSet = setActivePlanByCode(verifiedPlanCode);
      if (didSet && userId != null) _cacheActivePlanForUser(userId);
    }
  }

  void _restoreActivePlanFromStorage() {
    if (activePlan.value != null) return;

    final userId = _readUserIdFromStorage();
    if (userId == null) return;

    final raw = _box.read(_activePlanKey(userId));
    if (raw is! Map) return;

    try {
      activePlan.value = _subscriptionPlanFromJson(
        Map<String, dynamic>.from(raw),
      );
    } catch (e) {
      print('Failed to restore active plan from storage: $e');
    }
  }

  int? _readUserIdFromStorage() {
    final raw = _box.read(_userIdKey);
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  int? _resolveCurrentUserId() {
    final storedUserId = _readUserIdFromStorage();
    if (storedUserId != null) return storedUserId;

    if (!Get.isRegistered<ProfileController>()) return null;

    final profileUserId = Get.find<ProfileController>().profile.value?.user.id;
    if (profileUserId != null) _box.write(_userIdKey, profileUserId);

    return profileUserId;
  }

  String couponErrorFor(int planId) => couponErrorMap[planId] ?? '';

  SubscriptionPurchaseData? previewFor(int planId) => previewMap[planId];

  bool isApplyingCoupon(int planId) {
    return applyingCouponMap[planId] ?? false;
  }

  void _cacheActivePlanForUser(int userId) {
    final plan = activePlan.value;
    if (plan == null) return;

    final unlockedFeatures = plan.features.map((f) => f.featureTitle).toList();
    _box.write(_userFeaturesKey(userId), unlockedFeatures);
    _box.write(_activePlanKey(userId), _subscriptionPlanToJson(plan));
  }

  void _clearCachedActivePlan(int userId) {
    _box.remove(_userFeaturesKey(userId));
    _box.remove(_activePlanKey(userId));
  }

  plan_models.SubscriptionPlan _subscriptionPlanFromHistory(
    history_models.Plan plan,
  ) {
    return plan_models.SubscriptionPlan(
      id: plan.id,
      planName: plan.planName,
      planCode: plan.planCode,
      planType: plan.planType,
      amount: plan.amount,
      durationDays: plan.durationDays,
      description: plan.description,
      isRecommended: plan.isRecommended,
      isAddon: plan.isAddon,
      features: plan.features
          .map(
            (feature) => plan_models.Feature(
              id: feature.id,
              featureCode: feature.featureCode ?? '',
              featureTitle: feature.featureTitle,
              featureDescription: feature.featureDescription,
              isEnabled: feature.isEnabled ?? false,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> _subscriptionPlanToJson(
    plan_models.SubscriptionPlan plan,
  ) {
    return {
      'id': plan.id,
      'plan_name': plan.planName,
      'plan_code': plan.planCode,
      'plan_type': plan.planType,
      'amount': plan.amount,
      'duration_days': plan.durationDays,
      'description': plan.description,
      'is_recommended': plan.isRecommended,
      'is_addon': plan.isAddon,
      'features': plan.features
          .map(
            (feature) => {
              'id': feature.id,
              'feature_code': feature.featureCode,
              'feature_title': feature.featureTitle,
              'feature_description': feature.featureDescription,
              'is_enabled': feature.isEnabled,
            },
          )
          .toList(),
    };
  }

  plan_models.SubscriptionPlan _subscriptionPlanFromJson(
    Map<String, dynamic> json,
  ) {
    return plan_models.SubscriptionPlan.fromJson(json);
  }

  int _parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.parse(cleaned).round();
  }

  String _normalizeText(String value) => value.trim().toLowerCase();

  String _normalizeFeatureText(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
