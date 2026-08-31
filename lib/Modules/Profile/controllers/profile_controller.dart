import 'dart:io';

import 'package:Gixa/Modules/Profile/models/profile_model.dart';
import 'package:Gixa/Modules/ProfileProgress/controller/profile_progress_controller.dart';
import 'package:Gixa/Modules/subscription/controller/subsciption_history_controller.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import 'package:Gixa/Modules/updateProfile/model/update_profile.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';
import 'package:Gixa/commonmodels/category_model.dart';
import 'package:Gixa/commonmodels/course_model.dart';
import 'package:Gixa/commonmodels/state_model.dart';
import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';
import 'package:Gixa/network/app_exception.dart';
import 'package:Gixa/services/profile_services.dart';
import 'package:Gixa/services/register_master_api.dart';
import 'package:Gixa/services/token_services.dart';
import 'package:Gixa/services/update_profile_services.dart';
import 'package:Gixa/utils/fcm_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProfileController extends GetxController {
  final GetStorage _box = GetStorage();
  final RegisterMasterApi _masterApi = RegisterMasterApi();
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  final Rxn<ProfileModel> profile = Rxn<ProfileModel>();
  final RxBool hasRankEditAccess = true.obs;
  final RxBool rankEditRequiresPremium = false.obs;
  final RxnInt activeRankEditGrantId = RxnInt();
  // IDs received from the backend (the profile returns string names, but PUT needs int IDs)
  final RxnInt selectedCategoryId = RxnInt();
  final RxnInt selectedStateId = RxnInt();
  final RxnInt selectedCourseId = RxnInt();
  final Map<String, int> _categoryIdByName = {};
  final Map<String, int> _stateIdByName = {};
  final Map<String, int> _courseIdByName = {};
  final RxSet<int> _ugCourseIds = <int>{}.obs;

  // ── PG Cascading Dropdown States ──
  final RxString selectedCourseLevel = 'UG'.obs;
  final RxString selectedCourseCategory = ''.obs;
  final Rxn<CourseModel> selectedCourseModel = Rxn<CourseModel>();
  final Map<String, Map<String, List<CourseModel>>> structuredCourses = {};
  
  final List<CourseModel> ugCourseList = [];
  final List<CourseModel> pgCourseList = [];
  
  List<String> get availableCourseCategories {
    if (selectedCourseLevel.value.isEmpty) return [];
    return structuredCourses[selectedCourseLevel.value]?.keys.toList() ?? [];
  }
  
  List<CourseModel> get availableCourses {
    if (selectedCourseLevel.value.isEmpty || selectedCourseCategory.value.isEmpty) return [];
    return structuredCourses[selectedCourseLevel.value]?[selectedCourseCategory.value] ?? [];
  }
  
  List<String> get availableSpecialties {
    final cModel = selectedCourseModel.value;
    if (cModel == null) return [];
    return cModel.specialties.map((e) => e.name).toList();
  }

  bool get isUGUser {
    final level = profile.value?.courseLevel;
    if (level != null && level.isNotEmpty) {
      return level.toUpperCase() == 'UG';
    }
    final cId = selectedCourseId.value;
    if (cId == null) return true; // Default to UG
    return _ugCourseIds.contains(cId);
  }

  bool isCourseUG(int courseId) => _ugCourseIds.contains(courseId);

  bool get isPGUser => !isUGUser;

  Future<void>? _loadFuture;
  File? selectedProfileImage;

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final tenthCtrl = TextEditingController();
  final twelthCtrl = TextEditingController();
  final pcbCtrl = TextEditingController();
  final nationalityCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final RxString genderValue = ''.obs;
  final neetCtrl = TextEditingController();
  final courseCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final casteCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final specialtyCtrl = TextEditingController(); // NEW
  final neetScoreCtrl = TextEditingController();
  final airCtrl = TextEditingController();
  final disabilityCtrl = TextEditingController();
  final horizontalReservationCtrl = TextEditingController();
  final mobilectrl = TextEditingController();

  bool get isRankLocked => !hasRankEditAccess.value;

  ProfileProgressController get progressController =>
      Get.isRegistered<ProfileProgressController>()
      ? Get.find<ProfileProgressController>()
      : Get.put(ProfileProgressController());

  SubscriptionController get subscriptionController =>
      Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>()
      : Get.put(SubscriptionController());

  SubscriptionHistoryController get subscriptionHistoryController =>
      Get.isRegistered<SubscriptionHistoryController>()
      ? Get.find<SubscriptionHistoryController>()
      : Get.put(SubscriptionHistoryController());

  @override
  void onInit() {
    super.onInit();
  }

  String _rankPremiumGrantUsedKey(int userId) =>
      'rank_premium_grant_used_$userId';

  String _syncedFcmTokenKey(int userId) => 'synced_fcm_token_$userId';

  int? _currentUserId() {
    final profileUserId = profile.value?.user.id;
    if (profileUserId != null) {
      return profileUserId;
    }

    final raw = _box.read('user_id');
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  int? _usedPremiumGrantId(int userId) {
    final raw = _box.read(_rankPremiumGrantUsedKey(userId));
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  Future<int?> _resolveActiveRankEditGrantId({
    bool forceRefreshSubscription = false,
  }) async {
    await subscriptionController.ensureActivePlanReady(
      forceRefresh: forceRefreshSubscription,
    );

    if (!subscriptionController.isSubscribed) {
      activeRankEditGrantId.value = null;
      return null;
    }

    await subscriptionHistoryController.ensureLoaded(
      forceRefresh: forceRefreshSubscription,
    );

    for (final item in subscriptionHistoryController.historyList) {
      if (item.isActive) {
        activeRankEditGrantId.value = item.id;
        return item.id;
      }
    }

    activeRankEditGrantId.value = null;
    return null;
  }

  Future<void> refreshRankEditAccess({
    bool forceRefreshSubscription = false,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      hasRankEditAccess.value = false;
      rankEditRequiresPremium.value = true;
      return;
    }

    final profileFlag = profile.value?.allIndiaRankUpdatedOnce ?? false;

    // First time free edit
    if (!profileFlag) {
      hasRankEditAccess.value = true;
      rankEditRequiresPremium.value = false;
      return;
    }

    // Has used free edit. Check if they have an active plan.
    final activeGrantId = await _resolveActiveRankEditGrantId(
      forceRefreshSubscription: forceRefreshSubscription,
    );

    if (activeGrantId == null) {
      hasRankEditAccess.value = false;
      rankEditRequiresPremium.value = true;
      return;
    }

    // Has an active plan. Check if they already used it for this plan.
    final usedGrantId = _usedPremiumGrantId(userId);
    if (usedGrantId == activeGrantId) {
      hasRankEditAccess.value = false;
      rankEditRequiresPremium.value = true;
    } else {
      hasRankEditAccess.value = true;
      rankEditRequiresPremium.value = false;
    }
  }

  Future<void> _consumeRankEditIfNeeded({
    required bool didChangeRank,
    bool forceRefreshSubscription = false,
  }) async {
    if (!didChangeRank) return;

    final userId = _currentUserId();
    if (userId == null) return;

    final profileFlag = profile.value?.allIndiaRankUpdatedOnce ?? false;
    
    // If they haven't used the free edit yet, it doesn't consume the premium grant
    if (!profileFlag) return;

    final activeGrantId = await _resolveActiveRankEditGrantId(
      forceRefreshSubscription: forceRefreshSubscription,
    );

    if (activeGrantId != null) {
      await _box.write(_rankPremiumGrantUsedKey(userId), activeGrantId);
    }
  }

  Future<void> ensureLoaded({bool force = false}) async {
    if (!force && profile.value != null) {
      return;
    }

    final inFlight = _loadFuture;
    if (!force && inFlight != null) {
      return inFlight;
    }

    final future = fetchProfile(force: force);
    _loadFuture = future;

    try {
      await future;
    } finally {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    }
  }

  Future<void> fetchProfile({bool force = false}) async {
    if (isLoading.value) return;

    final hasToken = await TokenService.hasValidToken();
    if (!hasToken) return;

    isLoading.value = true;

    try {
      final result = await ProfileService.getProfile(forceRefresh: force);

      // ───── DEBUG: GET /profile response ─────

      // ────────────────────────────────────────────

      profile.value = result;
      _box.write('user_id', result.user.id);
      
      await _ensureMasterMappingsLoaded(); // NEW: Ensure mappings exist before fill
      
      _fillControllers(result);
      progressController.updateProfile(result);
      progressController.update();
      await _syncFcmToken(result);
      await refreshRankEditAccess(forceRefreshSubscription: force);
    } catch (e) {
      AppSnackbar.show("Profile Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Like [fetchProfile] but does NOT check the [isLoading] guard.
  /// Used inside [saveProfileChanges] so the save's isLoading=true
  /// stays set without a mid-save toggle (one clean spinner).
  Future<void> _doFetchUnguarded({bool force = false}) async {
    final hasToken = await TokenService.hasValidToken();
    if (!hasToken) return;
    try {
      final result = await ProfileService.getProfile(forceRefresh: force);
      // ───── DEBUG: GET /profile response (post-save refresh) ─────

      profile.value = result;
      _box.write('user_id', result.user.id);
      
      await _ensureMasterMappingsLoaded(); // NEW: Ensure mappings exist before fill
      
      _fillControllers(result);
      progressController.updateProfile(result);
      progressController.update();
      await refreshRankEditAccess(forceRefreshSubscription: force);
    } catch (e) {
      AppSnackbar.show("Profile Error", e.toString());
    }
  }

  String _normalizeDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    final iso = DateTime.tryParse(raw);
    if (iso != null) return raw.split('T').first;

    final parts = raw.split(RegExp(r'[-/.]'));
    if (parts.length == 3 && parts[0].length <= 2) {
      final reordered =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      if (DateTime.tryParse(reordered) != null) {
        return reordered;
      }
    }

    return raw;
  }

  Future<void> enableEdit() async {
    if (profile.value == null) return;
    await refreshRankEditAccess(forceRefreshSubscription: true);
    isEditMode.value = true;
  }

  void _fillControllers(ProfileModel p) {
    final normalizedGender = _normalizeGenderValue(p.gender);
    firstNameCtrl.text = p.user.firstName ?? '';
    lastNameCtrl.text = p.user.lastName ?? '';
    emailCtrl.text = p.user.email ?? '';
    mobilectrl.text = p.user.mobileNumber ?? '';
    addressCtrl.text = p.address ?? '';
    dobCtrl.text = _normalizeDate(p.dateOfBirth);
    tenthCtrl.text = p.tenthPercentage ?? '';
    twelthCtrl.text = p.twelthPercentage ?? '';
    final pcbRaw = p.twelthPcb?.toString() ?? '';

    if (pcbRaw.isEmpty) {
      pcbCtrl.text = '';
    } else {
      final pcbValue = double.tryParse(pcbRaw);

      if (pcbValue == null) {
        pcbCtrl.text = pcbRaw;
      } else {
        pcbCtrl.text = pcbValue % 1 == 0
            ? pcbValue.toInt().toString()
            : pcbValue
                  .toString()
                  .replaceAll(RegExp(r'0+$'), '')
                  .replaceAll(RegExp(r'\.$'), '');
      }
    }
    nationalityCtrl.text = p.nationality ?? '';

    // Debug print for gender value from backend
    // ignore: avoid_print
    print(
      '[ProfileController] Gender from backend: \'${p.gender}\' (normalized: \'${normalizedGender}\')',
    );

    // Fallback: if gender is null/empty/unexpected, set to 'Other'
    if (normalizedGender == null ||
        normalizedGender.isEmpty ||
        !(normalizedGender == 'M' ||
            normalizedGender == 'F' ||
            normalizedGender == 'Other')) {
      genderValue.value = 'Other';
    } else {
      genderValue.value = normalizedGender;
    }
    genderCtrl.text = _genderLabel(genderValue.value);

    neetCtrl.text = p.neetScore?.toString() ?? '';
    neetScoreCtrl.text = p.neetScore?.toString() ?? '';
    airCtrl.text = p.allIndiaRank?.toString() ?? '';
    casteCtrl.text = p.caste ?? '';

    // ── Course / State / Category ──
    // The backend returns string names (e.g. "MBBS", "Maharashtra", "ST").
    // Parse them as int IDs if possible; store both the display text AND the ID.
    final rawCourse = p.course ?? '';
    final rawState = p.state ?? '';
    final rawCategory = p.category ?? '';

    courseCtrl.text = rawCourse;
    stateCtrl.text = rawState;
    categoryCtrl.text = rawCategory;

    selectedCourseId.value = p.courseId ?? _resolveCourseId(rawCourse) ?? int.tryParse(rawCourse);
    selectedStateId.value = p.stateId ?? _resolveStateId(rawState) ?? int.tryParse(rawState);
    selectedCategoryId.value = p.categoryId ?? _resolveCategoryId(rawCategory) ?? int.tryParse(rawCategory);

    specialtyCtrl.text = p.specialty ?? '';

    // Initialize cascaded dropdowns if possible (assumes ensureMasterMappingsLoaded was called during fetchProfile)
    _syncCascadingDropdownsFromProfile(p);

    disabilityCtrl.text = p.disabilityDetails ?? '';
    horizontalReservationCtrl.text = (p.horizontals ?? []).join(', ');
  }

  void cancelEdit() {
    isEditMode.value = false;
    selectedProfileImage = null;
  }

  void setProfileImage(File file) {
    selectedProfileImage = file;
  }

  Future<void> refreshProfile() async {
    await fetchProfile(force: true);
  }

  void clearProfile() {
    profile.value = null;
    selectedProfileImage = null;
    _loadFuture = null;
    hasRankEditAccess.value = true;
    rankEditRequiresPremium.value = false;
    // activeRankEditGrantId.value = null;
    selectedCategoryId.value = null;
    selectedStateId.value = null;
    selectedCourseId.value = null;
    mobilectrl.clear();
    firstNameCtrl.clear();
    lastNameCtrl.clear();
    emailCtrl.clear();
    addressCtrl.clear();
    dobCtrl.clear();
    tenthCtrl.clear();
    twelthCtrl.clear();
    pcbCtrl.clear();
    nationalityCtrl.clear();
    genderCtrl.clear();
    genderValue.value = '';
    neetCtrl.clear();
    courseCtrl.clear();
    stateCtrl.clear();
    casteCtrl.clear();
    categoryCtrl.clear();
    neetScoreCtrl.clear();
    airCtrl.clear();
    specialtyCtrl.clear();
    selectedCourseLevel.value = 'UG';
    selectedCourseCategory.value = '';
    selectedCourseModel.value = null;
  }

  Future<void> deleteProfileImage() async {
    try {
      isLoading.value = true;

      await ProfileService.deleteProfileImage();
      selectedProfileImage = null;
      await _doFetchUnguarded(force: true);

      AppSnackbar.show(
        "Success",
        "Profile image removed successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      AppSnackbar.show(
        "Error",
        "Failed to remove profile image",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    await saveProfileChanges();
  }

  Future<void> saveProfileChanges() async {
    if (isLoading.value) return;

    try {
      // ───── DEBUG: UI field values before building PUT request ─────

      // ────────────────────────────────────────────
      final newNeetScoreText = neetScoreCtrl.text.trim();
      final airText = airCtrl.text.trim();
      final casteText = casteCtrl.text.trim();
      final specialtyText = specialtyCtrl.text.trim();

      final existingRank = profile.value?.allIndiaRank;
      final existingNeetScore = profile.value?.neetScore ?? 0;
      final existingCategoryText = profile.value?.category ?? '';
      final canUpdateNeetScore = existingNeetScore <= 0;
      final parsedNewNeetScore = int.tryParse(newNeetScoreText);
      final parsedAir = int.tryParse(airText);
      final existingRankText = existingRank?.toString() ?? '';
      final didChangeRank = airText != existingRankText;
      final categoryText = categoryCtrl.text.trim();
      final didChangeCategory =
          _normalizeLookup(categoryText) !=
          _normalizeLookup(existingCategoryText);

      if (parsedNewNeetScore != null && parsedNewNeetScore > 720) {
        AppSnackbar.show(
          "Invalid NEET Score",
          "NEET score must be between 0 and 720",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (!canUpdateNeetScore) {
        final attemptedNeetChange = newNeetScoreText.isEmpty
            ? true
            : parsedNewNeetScore == null ||
                  parsedNewNeetScore != existingNeetScore;

        if (attemptedNeetChange) {
          AppSnackbar.show(
            "NEET Score Locked",
            "NEET score cannot be updated",
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      if (airText.isNotEmpty) {
        if (parsedAir == null) {
          AppSnackbar.show(
            "Invalid AIR",
            "Please enter a valid number",
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        if (parsedAir <= 0) {
          AppSnackbar.show(
            "Invalid AIR",
            "AIR must be greater than 0",
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      await refreshRankEditAccess(forceRefreshSubscription: true);

      if (didChangeRank && !hasRankEditAccess.value) {
        AppSnackbar.show(
          "Rank Locked",
          "For editing rank you need to buy a subscription plan.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await _ensureMasterMappingsLoaded();

      final effectiveStateId = _resolveStateId(stateCtrl.text);
      final effectiveCourseId = _resolveCourseId(courseCtrl.text);
      final effectiveCategoryId = _resolveCategoryId(categoryText);

      if (didChangeCategory &&
          categoryText.isNotEmpty &&
          effectiveCategoryId == null) {
        AppSnackbar.show(
          "Invalid Category",
          "Please enter a valid category name.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      selectedStateId.value = effectiveStateId;
      selectedCourseId.value = effectiveCourseId;
      selectedCategoryId.value = effectiveCategoryId;

      isLoading.value = true;

      final request = UpdateProfileRequest(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
        tenthPercentage: double.tryParse(tenthCtrl.text),
        twelthPercentage: double.tryParse(twelthCtrl.text),
        twelthPcb: double.tryParse(pcbCtrl.text),
        neetScore: canUpdateNeetScore ? parsedNewNeetScore : null,
        nationality: nationalityCtrl.text.trim().isEmpty
            ? null
            : nationalityCtrl.text.trim(),
        gender: genderValue.value.isEmpty ? null : genderValue.value,
        dateOfBirth: dobCtrl.text.isNotEmpty
            ? DateTime.tryParse(_normalizeDate(dobCtrl.text))
            : null,
        profilePicture: selectedProfileImage,
        air: didChangeRank ? parsedAir : existingRank,
        state: effectiveStateId,
        course: effectiveCourseId,
        category: effectiveCategoryId,
        specialty: specialtyText.isEmpty ? null : specialtyText,
        caste: casteText.isEmpty ? null : casteText,
        fcmToken: await FcmUtils.getFcmToken(),
      );

      final jsonPayload = request.toJson();

      final response = await UpdateProfileService.updateProfile(request);

      await _consumeRankEditIfNeeded(didChangeRank: didChangeRank);

      ApiClient.invalidateGetCache(
        endpointPrefixes: const [ApiEndpoints.profile],
      );

      await _doFetchUnguarded(force: true);

      selectedProfileImage = null;
      isEditMode.value = false;
      update();

      AppSnackbar.show(
        "Success",
        "Profile updated successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } on AppException catch (e) {
      AppSnackbar.show(
        "Update Failed",
        e.message.isNotEmpty ? e.message : "Rank update failed. Please contact support.",
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      AppSnackbar.show("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String get email => profile.value?.user.email ?? '';
  String get mobile => profile.value?.user.mobileNumber ?? '';

  String get fullName {
    final first = profile.value?.user.firstName ?? '';
    final last = profile.value?.user.lastName ?? '';
    return '$first $last'.trim();
  }

  String get profileImage => profile.value?.profilePictureUrl ?? '';
  bool get isProfileCompleted => profile.value?.isProfileCompleted ?? false;
  bool get isVerified => profile.value?.isVerified ?? false;

  void setGender(String value) {
    final normalizedGender = _normalizeGenderValue(value);
    genderValue.value = normalizedGender ?? '';
    genderCtrl.text = _genderLabel(genderValue.value);
  }

  String _genderLabel(String? value) {
    switch (_normalizeGenderValue(value)) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'Other':
        return 'Other';
      default:
        return '';
    }
  }

  String? _normalizeGenderValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'm':
      case 'male':
        return 'M';
      case 'f':
      case 'female':
        return 'F';
      case 'other':
        return 'Other';
      default:
        return value?.trim().isEmpty == true ? null : value?.trim();
    }
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  Future<void> _syncFcmToken(ProfileModel result) async {
    final token = await FcmUtils.getFcmToken();
    if (token.isEmpty) return;

    final userId = result.user.id;
    if (_box.read(_syncedFcmTokenKey(userId)) == token) {
      return;
    }

    try {
      final request = UpdateProfileRequest(
        firstName: result.user.firstName,
        lastName: result.user.lastName,
        address: result.address ?? '',
        email: result.user.email,
        air: result.allIndiaRank,
        neetScore: result.neetScore,
        tenthPercentage: _parseDouble(result.tenthPercentage),
        twelthPercentage: _parseDouble(result.twelthPercentage),
        twelthPcb: _parseDouble(result.twelthPcb),
        category: result.categoryId,
        state: result.stateId,
        course: result.courseId,
        specialty: result.specialty,
        caste: result.caste,
        nationality: result.nationality,
        gender: result.gender,
        dateOfBirth: result.dateOfBirth == null
            ? null
            : DateTime.tryParse(result.dateOfBirth!),
        fcmToken: token,
      );

      await UpdateProfileService.updateProfile(request);
      await _box.write(_syncedFcmTokenKey(userId), token);
    } catch (_) {
      // Keep profile loading working even if token sync fails.
    }
  }

  Future<void> _ensureMasterMappingsLoaded() async {
    if (_stateIdByName.isNotEmpty &&
        _courseIdByName.isNotEmpty &&
        _categoryIdByName.isNotEmpty) {
      return;
    }

    final data = await _masterApi.fetchMasters(showGlobalNetworkError: false);

    final states = data['states'] as List<StateModel>? ?? const [];
    final categories = data['categories'] as List<CategoryModel>? ?? const [];
    final ugCourses = data['courses_for_ug'] as List<CourseModel>? ?? const [];
    final allCourses = <CourseModel>[
      ...ugCourses,
      ..._flattenCourseBuckets(data['courses']),
    ];

    _stateIdByName
      ..clear()
      ..addEntries(
        states.map((state) => MapEntry(_normalizeLookup(state.name), state.id)),
      );

    _categoryIdByName
      ..clear()
      ..addEntries(
        categories.map(
          (category) => MapEntry(_normalizeLookup(category.name), category.id),
        ),
      );

    _courseIdByName.clear();
    _ugCourseIds.clear();
    for (final course in ugCourses) {
      _ugCourseIds.add(course.id);
    }
    for (final course in allCourses) {
      _courseIdByName[_normalizeLookup(course.name)] = course.id;
    }
    
    // Store structured courses
    final rawCourses = data['courses'];
    if (rawCourses is Map<String, Map<String, List<CourseModel>>>) {
      structuredCourses.clear();
      structuredCourses.addAll(rawCourses);
    }
    
    ugCourseList.clear();
    ugCourseList.addAll(ugCourses);

    final pgCourses = data['courses_for_pg'] as List<CourseModel>? ?? const [];
    pgCourseList.clear();
    pgCourseList.addAll(pgCourses);
    
    // Attempt to sync dropdowns if profile is loaded
    if (profile.value != null) {
      _syncCascadingDropdownsFromProfile(profile.value!);
    }
  }

  Iterable<CourseModel> _flattenCourseBuckets(dynamic rawCourses) sync* {
    if (rawCourses is! Map<String, dynamic>) return;

    for (final level in rawCourses.values) {
      if (level is! Map<String, dynamic>) continue;

      for (final bucket in level.values) {
        if (bucket is! List) continue;

        for (final item in bucket) {
          if (item is CourseModel) {
            yield item;
          }
        }
      }
    }
  }

  void _syncCascadingDropdownsFromProfile(ProfileModel p) {
    if (structuredCourses.isEmpty) return;
    
    final cId = p.courseId ?? int.tryParse(p.course ?? '');
    if (cId == null) {
      selectedCourseLevel.value = 'UG';
      return;
    }
    
    selectedCourseLevel.value = _ugCourseIds.contains(cId) ? 'UG' : 'PG';
    
    for (final levelEntry in structuredCourses.entries) {
      if (levelEntry.key != selectedCourseLevel.value) continue;
      
      for (final catEntry in levelEntry.value.entries) {
        for (final course in catEntry.value) {
          if (course.id == cId) {
            selectedCourseCategory.value = catEntry.key;
            selectedCourseModel.value = course;
            return;
          }
        }
      }
    }
  }

  int? _resolveStateId(String rawValue) {
    final parsed = _parseIdLikeValue(rawValue);
    return parsed ??
        selectedStateId.value ??
        _stateIdByName[_normalizeLookup(rawValue)];
  }

  int? _resolveCourseId(String rawValue) {
    final parsed = _parseIdLikeValue(rawValue);
    return parsed ??
        selectedCourseId.value ??
        _courseIdByName[_normalizeLookup(rawValue)];
  }

  int? _resolveCategoryId(String rawValue) {
    final parsed = _parseIdLikeValue(rawValue);
    return parsed ??
        _categoryIdByName[_normalizeLookup(rawValue)] ??
        selectedCategoryId.value;
  }

  int? _parseIdLikeValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String _normalizeLookup(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    mobilectrl.dispose();
    addressCtrl.dispose();
    dobCtrl.dispose();
    tenthCtrl.dispose();
    twelthCtrl.dispose();
    pcbCtrl.dispose();
    nationalityCtrl.dispose();
    genderCtrl.dispose();
    neetCtrl.dispose();
    courseCtrl.dispose();
    stateCtrl.dispose();
    casteCtrl.dispose();
    neetScoreCtrl.dispose();
    airCtrl.dispose();
    specialtyCtrl.dispose();
    super.onClose();
  }
}
