import 'dart:convert';

import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/predication/model/chat_message_model.dart';
import 'package:Gixa/Modules/predication/model/state_category_model.dart';
import 'package:Gixa/Modules/subscription/features/feature_names.dart';
import 'package:Gixa/commonmodels/category_model.dart';
import 'package:Gixa/commonmodels/course_model.dart';
import 'package:Gixa/commonmodels/round_model.dart';
import 'package:Gixa/commonmodels/specialty_model.dart';
import 'package:Gixa/commonmodels/state_model.dart';
import 'package:Gixa/network/app_exception.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:Gixa/services/prediction_services.dart';
import 'package:Gixa/services/register_master_api.dart';
import 'package:Gixa/services/state_category_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import '../model/predication_model.dart';
import '../view/ai_prediction_result_view.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class PredictionController extends GetxController {
  /// Syncs PredictionController fields with ProfileController's latest profile
  void syncWithProfile(dynamic profileController) {
    final p = profileController.profile.value;
    if (p == null) return;
    userAir.value = p.allIndiaRank ?? 0;
    userMarks.value = p.neetScore ?? 0;
    selectedState.value = p.state ?? "Select State";
    selectedCategory.value = p.category ?? "";
    selectedCourse.value = "Select Course";
    selectedSpecialty.value = "Select Specialty";
    selectedGender.value = p.gender ?? "M";
    selectedQuota.value = p.quota ?? "";
    selectedInstituteType.value = p.instituteType ?? "Both";
    if (p.horizontals != null && p.horizontals!.isNotEmpty) {
      selectedHorizontals.clear();

      lockedHorizontals.clear();
    } else {
      selectedHorizontals.clear();
      lockedHorizontals.clear();
    }
  }

  final ScrollController chatScrollController = ScrollController();

  void scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,

          duration: const Duration(milliseconds: 700),

          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String get effectiveState {
    if (selectedState.value == 'Select State' || selectedState.value.isEmpty) {
      return profileController.profile.value?.state ?? '';
    }
    return selectedState.value;
  }

  // Returns true if current state is Maharashtra
  bool get isMaharashtra =>
      effectiveState.trim().toLowerCase() == 'maharashtra';

  // Returns horizontal categories for Reservation (excludes IQ for Maharashtra)

  // Returns horizontal categories for Reservation (excludes IQ/I.Q for Maharashtra)
  List<String> get reservationHorizontals {
    if (isMaharashtra) {
      return horizontalCategoryList
          .where((e) => e != 'IQ' && e != 'I.Q')
          .toList();
    }
    return horizontalCategoryList;
  }

  /// CHATBOT
  final messages = <ChatMessageModel>[].obs;

  final isBotTyping = false.obs;

  final currentQuestionIndex = 0.obs;

  // Returns true if IQ or I.Q is available for Maharashtra
  bool get showIqQuotaTile =>
      isMaharashtra &&
      (horizontalCategoryList.contains('IQ') ||
          horizontalCategoryList.contains('I.Q'));

  // Returns the actual IQ label from backend for Maharashtra (IQ or I.Q)
  String get iqLabel => horizontalCategoryList.contains('I.Q') ? 'I.Q' : 'IQ';

  /// Returns the available quotas for the currently selected state
  List<String> get availableQuotasForSelectedState {
    final stateKey = stateCategoryMap.keys.firstWhere(
      (k) => k.toLowerCase() == effectiveState.trim().toLowerCase(),
      orElse: () => '',
    );
    final stateData = stateCategoryMap[stateKey];
    return stateData?.availableQuotas ?? [];
  }

  Future<void> startChatBot() async {
    messages.clear();

    await addBotMessage("""
Hey ${profileController.profile.value?.user.firstName ?? "Student"} 👋

I analyzed your profile.

🎯 AIR Rank: ${userAir.value}
📚 Category: ${selectedCategory.value}
📍 Home State: ${selectedState.value}

Let's find best colleges for you 🚀
""");

    askStateQuestion();
  }

  Future<void> addBotMessage(
    String text, {
    List<String>? options,
    String? key,
  }) async {
    isBotTyping.value = true;

    await Future.delayed(const Duration(milliseconds: 900));

    isBotTyping.value = false;

    messages.add(
      ChatMessageModel(
        message: text,
        isBot: true,
        options: options,
        questionKey: key,
      ),
    );

    scrollChatToBottom();
  }

  void askInstituteQuestion() {
    addBotMessage(
      "What type of colleges do you prefer?",
      options: ["Government", "Private", "Both"],
      key: "institute",
    );
  }

  void askCourseQuestion() {
    addBotMessage(
      "Which course are you interested in?",
      options: currentAvailableCourses.map((e) => e.name).toList(),
      key: "course",
    );
  }

  void askQuotaQuestion() {
    addBotMessage(
      "Select quota preference",
      options: availableQuotasForSelectedState,
      key: "quota",
    );
  }

  void askStateQuestion() {
    addBotMessage(
      "Which state are you targeting?",
      options: stateList.map((e) => e.name).toList(),
      key: "state",
    );
  }

  Future<void> handleAnswer({
    required String key,
    required String answer,
  }) async {
    addUserMessage(answer);

    /// STATE
    if (key == "state") {
      selectedState.value = answer;

      updateCategoriesByState(answer);

      askInstituteQuestion();
    }
    /// INSTITUTE
    else if (key == "institute") {
      if (answer == "Government") {
        selectedInstituteType.value = "Govt";
      } else if (answer == "Private") {
        selectedInstituteType.value = "Pvt";
      } else {
        selectedInstituteType.value = "Both";
      }

      askCourseQuestion();
    }
    /// COURSE
    else if (key == "course") {
      selectedCourse.value = answer;

      askQuotaQuestion();
    }
    /// QUOTA
    else if (key == "quota") {
      selectedQuota.value = answer;

      await generatePrediction();
    }
  }

  Future<void> generatePrediction() async {
    await addBotMessage("""
✨ Perfect!

Generating your AI college prediction...
""");

    await fetchPrediction(minimumLoadingDuration: const Duration(seconds: 2));
  }

  void addUserMessage(String text) {
    messages.add(ChatMessageModel(message: text, isBot: false));

    scrollChatToBottom();
  }

  final SubscriptionController subscriptionController =
      Get.find<SubscriptionController>();
  final ProfileController profileController = Get.find<ProfileController>();

  bool get canAccessPrediction => subscriptionController.hasFeature(
    FeatureNames.selectedStateCollegePrediction,
  );

  bool get isFreeUser => !subscriptionController.isSubscribed;

  /// =========================
  /// STORAGE
  /// =========================
  final box = GetStorage();

  /// =========================
  /// LOADING STATES
  /// =========================
  var isInitializing = false.obs;
  var isProfileLoading = false.obs;
  var isPredictionLoading = false.obs;
  var errorMessage = ''.obs;
  var courseError = ''.obs;
  Future<void>? _bootstrapFuture;

  /// =========================
  /// PROFILE DATA
  /// =========================
  var userAir = 0.obs;
  var userMarks = 0.obs;

  /// =========================
  /// GENDER INPUT (MANUAL)
  /// =========================
  var selectedGender = "M".obs;

  final genderList = [
    {"label": "Male", "value": "M"},
    {"label": "Female", "value": "F"},
    {"label": "Other", "value": "Other"},
  ];

  // =========================
  // PREMIUM / FEATURE ACCESS
  // =========================

  /// Helper specifically for prediction (optional, can use canAccessPrediction directly)
  bool get isPredictionUnlocked {
    final unlocked = canAccessPrediction;
    print("ðŸ”¥ Premium Access: $unlocked");
    return unlocked;
  }

  var selectedState = "".obs;
  var selectedCategory = "".obs;
  var selectedCourse = "Select Course".obs;
  var selectedSpecialty = "Select Specialty".obs;

  var roundsList = <RoundModel>[].obs;
  var selectedRound = "".obs;
  var selectedRoundId = 0.obs;

  var selectedYear = RxnInt();
  var selectedQuota = "".obs;

  var stateCategoryMap = <String, StateCategoryModel>{}.obs;
  var horizontalCategoryList = <String>[].obs;
  var selectedInstituteType = "Both".obs;

  // var selectedHorizontal = "".obs;
  var selectedHorizontals = <String>[].obs;
  final lockedHorizontals = <String>[].obs;

  var predictionData = Rxn<PredictionData>();
  var recentPredictions = <Map<String, dynamic>>[].obs;

  /// Master lists
  var stateList = <StateModel>[].obs;
  var categoryList = <CategoryModel>[].obs;
  var courseList = <CourseModel>[].obs;
  var specialtyList = <SpecialtyModel>[].obs; // NEW
  var statewisePgCourses = <String, List<CourseModel>>{}.obs;

  List<CourseModel> get currentAvailableCourses {
    if (profileController.isUGUser) {
      return courseList; // populated with UG courses from loadMasters
    } else {
      final stateName = effectiveState;
      if (statewisePgCourses.containsKey(stateName) &&
          statewisePgCourses[stateName]!.isNotEmpty) {
        return statewisePgCourses[stateName]!;
      }
      return profileController.pgCourseList; // fallback
    }
  }

  void _logPredictionRequest(Map<String, dynamic> requestBody) {
    final pretty = const JsonEncoder.withIndent('  ').convert(requestBody);
    print("========== PREDICTION REQUEST (OUTGOING) ==========");
    print(pretty);
    print("===================================================");
  }

  String _getFormattedHorizontal() {
    if (selectedHorizontals.isEmpty) {
      return "";
    }

    final cleaned = selectedHorizontals
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return cleaned.join(",");
  }

  void handleHorizontalSelection(String label) {
    /// LOCKED ITEMS
    if (lockedHorizontals.contains(label)) {
      AppSnackbar.show(
        "Locked Reservation",
        "This reservation category is synced from your profile.",
      );

      return;
    }

    /// REMOVE
    if (selectedHorizontals.contains(label)) {
      selectedHorizontals.remove(label);
    } else {
      /// LIMIT 2
      if (selectedHorizontals.length >= 2) {
        AppSnackbar.show(
          "Limit Reached",
          "You can select only 2 reservation categories.",
        );

        return;
      }

      selectedHorizontals.add(label);
    }

    /// FORCE UPDATE
    selectedHorizontals.refresh();

    print("🔥 Selected Horizontals: $selectedHorizontals");
  }

  String _getFormattedQuota() {
    // If user did not select quota (value is empty or only whitespace), send empty string
    if (selectedQuota.value.trim().isEmpty) {
      return "";
    }
    // If IQ is selected, send Management Quota
    // if (selectedHorizontals.contains("IQ")) {
    //   return "Management Quota";
    // }
    // Otherwise, send the selected qu ota value
    return selectedQuota.value.trim();
  }

  String _getFormattedInstituteType() {
    switch (selectedInstituteType.value) {
      case "Govt":
        return "govt";
      case "Pvt":
        return "private";
      case "Both":
        return "both";
      default:
        return "";
    }
  }

  Future<void> loadStatewiseCategories({
    bool showGlobalNetworkError = false,
    bool forceRefresh = false,
  }) async {
    try {
      final responseMap = await StateCategoryApiService.getStateCategories(
        showGlobalNetworkError: showGlobalNetworkError,
        forceRefresh: forceRefresh,
      );

      final List<StateCategoryModel> data = responseMap['categories'] ?? [];
      final List rawSelectedCourses = responseMap['selected_courses'] ?? [];

      if (rawSelectedCourses.isNotEmpty) {
        final fetchedSelectedCourses = rawSelectedCourses
            .whereType<Map<String, dynamic>>()
            .map((e) => CourseModel.fromJson(e))
            .toList();

        if (fetchedSelectedCourses.isNotEmpty) {
          courseList.assignAll(fetchedSelectedCourses);

          print(
            "====== COURSES FROM BACKEND FOR STATE: ${selectedState.value} ======",
          );
          for (var c in fetchedSelectedCourses) {
            print("- ${c.name} (ID: ${c.id})");
          }
          print(
            "===================================================================",
          );

          final hasSelectedCourse = courseList.any(
            (course) => course.name == selectedCourse.value,
          );
          if (!hasSelectedCourse) {
            selectedCourse.value = courseList.first.name;
          }
        }
      }

      stateCategoryMap.clear();
      if (data.isEmpty) {
        stateList.clear();
        categoryList.clear();
        horizontalCategoryList.clear();
        selectedState.value = "Select State";
        return;
      }

      // Update stateList to only those states returned by the API
      // StateCategoryModel from statewiseAvailability API does not provide id, so use 0 as a placeholder
      stateList.value = data
          .map((e) => StateModel(id: 0, name: e.state))
          .toList();

      for (var item in data) {
        stateCategoryMap[item.state] = item;
      }
      final matchedState = stateList.firstWhere(
        (state) => state.name.toLowerCase() == selectedState.value.toLowerCase(),
        orElse: () => StateModel(id: 0, name: ''),
      );
      if (selectedState.value != 'Select State' && matchedState.name.isEmpty) {
        selectedState.value = "Select State";
      } else if (matchedState.name.isNotEmpty) {
        selectedState.value = matchedState.name;
      }

      if (effectiveState.isNotEmpty) {
        updateCategoriesByState(effectiveState, preserveExistingCategory: true);
      }
    } catch (e) {
      print("âŒ Failed to load statewise categories: $e");
    }
  }

  void updateCategoriesByState(
    String state, {
    bool preserveExistingCategory = false,
  }) {
    final stateKey = stateCategoryMap.keys.firstWhere(
      (k) => k.toLowerCase() == state.trim().toLowerCase(),
      orElse: () => '',
    );
    final data = stateCategoryMap[stateKey];
    if (data == null) return;

    final previousCategory = selectedCategory.value.trim();

    /// Update categories
    categoryList.value = data.availableCategories
        .asMap()
        .entries
        .map(
          (entry) =>
              CategoryModel(id: entry.key, name: entry.value, totalSeats: 0),
        )
        .toList();

    /// Update horizontal categories
    horizontalCategoryList.value = data.availableHorizontalCategories;

    /// Keep profile/user selected category when possible.
    if (preserveExistingCategory && previousCategory.isNotEmpty) {
      final exists = categoryList.any((e) => e.name == previousCategory);
      selectedCategory.value = exists
          ? previousCategory
          : (categoryList.isNotEmpty ? categoryList.first.name : "");
    } else {
      selectedCategory.value = categoryList.isNotEmpty
          ? categoryList.first.name
          : "";
    }

    /// Preserve already selected horizontals
    final currentSelections = List<String>.from(selectedHorizontals);

    selectedHorizontals.clear();

    /// Restore locked horizontals
    selectedHorizontals.addAll(lockedHorizontals);

    /// Restore previous selections
    for (final item in currentSelections) {
      if (!selectedHorizontals.contains(item) &&
          horizontalCategoryList.contains(item)) {
        selectedHorizontals.add(item);
      }
    }
  }

  void onStateChanged(String state) {
    selectedState.value = state;
    updateCategoriesByState(effectiveState);
  }

  void loadRecentPredictions() {
    final List? recent = box.read("recent_predictions");
    recentPredictions.assignAll(
      (recent ?? []).whereType<Map<String, dynamic>>(),
    );
  }

  @override
  void onInit() {
    super.onInit();

    selectedYear.value = DateTime.now().year;
    loadRecentPredictions();
  }

  Future<void> ensureBootstrap({bool forceRefresh = false}) async {
    final inFlight = _bootstrapFuture;
    if (!forceRefresh && inFlight != null) {
      return inFlight;
    }

    final future = initializePredictionInputs(forceRefresh: forceRefresh);
    _bootstrapFuture = future;

    try {
      await future;
    } finally {
      if (identical(_bootstrapFuture, future)) {
        _bootstrapFuture = null;
      }
    }
  }

  Future<void> initializePredictionInputs({bool forceRefresh = false}) async {
    if (isInitializing.value && !forceRefresh) return;

    isInitializing.value = true;
    try {
      await fetchUserProfile(forceRefresh: forceRefresh);
      syncWithProfile(profileController);
      
      final subCtrl = Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : Get.put(SubscriptionController());
      await subCtrl.loadStates();
      
      await loadMasters(forceRefresh: forceRefresh);
      await loadStatewiseCategories(forceRefresh: forceRefresh);
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> refreshPageData() async {
    await ensureBootstrap(forceRefresh: true);
  }

  // FETCH USER PROFILE
  Future<void> fetchUserProfile({
    bool showGlobalNetworkError = false,
    bool forceRefresh = false,
  }) async {
    try {
      isProfileLoading.value = true;
      errorMessage.value = '';

      await profileController.ensureLoaded(force: forceRefresh);
      syncWithProfile(profileController);
    } on AppException catch (e) {
      errorMessage.value = e.message;
      AppSnackbar.show("Error", e.message);
    } catch (e) {
      errorMessage.value = "Failed to load profile";
      AppSnackbar.show("Error", "Unable to fetch profile");
    } finally {
      isProfileLoading.value = false;
    }
  }

  // =====================================================
  // VALIDATE INPUT
  // =====================================================
  bool _validateInputs() {
    bool isValid = true;

    if (selectedCourse.value.trim().isEmpty ||
        selectedCourse.value == 'Select Course') {
      courseError.value = "Please select a course";
      isValid = false;
    } else {
      courseError.value = "";
    }

    bool hasSpecialties = false;
    final targetList = profileController.isPGUser
        ? profileController.pgCourseList
        : profileController.ugCourseList;
    for (final course in targetList) {
      if (course.name == selectedCourse.value) {
        if (course.specialties.isNotEmpty) hasSpecialties = true;
        break;
      }
    }

    if (hasSpecialties &&
        (selectedSpecialty.value.trim().isEmpty ||
            selectedSpecialty.value == 'Select Specialty')) {
      AppSnackbar.show("Error", "Please select a specialty");
      isValid = false;
    }

    if (userAir.value == 0) {
      AppSnackbar.show("Error", "AIR not found in profile");
      isValid = false;
    }

    if (selectedQuota.value.trim().isEmpty) {
      AppSnackbar.show("Error", "Please select quota");
      isValid = false;
    }

    if (effectiveState.trim().isEmpty ||
        selectedCategory.value.trim().isEmpty ||
        selectedYear.value == null) {
      AppSnackbar.show("Error", "Please fill all required fields");
      isValid = false;
    }

    return isValid;
  }

  // =====================================================
  // FETCH PREDICTION
  // =====================================================
  Future<void> fetchPrediction({
    Duration minimumLoadingDuration = Duration.zero,
  }) async {
    final startedAt = DateTime.now();
    final instituteType = _getFormattedInstituteType();
    final formattedQuota = _getFormattedQuota();

    if (!_validateInputs()) return;

    try {
      isPredictionLoading.value = true;
      errorMessage.value = '';

      /// ðŸ”¥ CLEAN REQUEST BODY (remove nulls)
      final formattedHorizontal = _getFormattedHorizontal();

      final requestBody = {
        "year": selectedYear.value,
        "rank": userAir.value,
        "marks": userMarks.value,
        "course": selectedCourse.value.trim(),
        "course_level": profileController.isPGUser ? "PG" : "UG",
        if (selectedSpecialty.value.isNotEmpty &&
            selectedSpecialty.value != 'Select Specialty')
          "specialty": selectedSpecialty.value.trim(),
        "state": effectiveState.trim(),
        "category": selectedCategory.value.trim(),
        "gender": selectedGender.value,
        // if (isPwd.value) "pwd": true,
        // if (isDefence.value) "defence": "DEFENCE",
        // if (isMinority.value) "minority": true,
        // if (isOrphan.value) "orphan": true,
        // if (isHillyArea.value) "hilly_area": true,
        "horizontal": formattedHorizontal,

        if (instituteType.isNotEmpty) "institute_type": instituteType,
        if (formattedQuota.isNotEmpty) "quota": formattedQuota,
      };
      print("Selected Horizontals: $selectedHorizontals");
      print("Formatted Horizontal: $formattedHorizontal");

      _logPredictionRequest(requestBody);

      final data = await PredictionService.fetchPrediction(requestBody);

      print("ðŸ“¦ FULL RESPONSE OBJECT: $data");

      try {
        print("ðŸ“¦ RESPONSE JSON: ${jsonEncode(data)}");
      } catch (e) {
        print("âš ï¸ Cannot convert to JSON: $e");
      }

      predictionData.value = data;

      if (data.message != null) {
        print('API Message: \\${data.message}');
      }

      box.write("last_prediction", requestBody);

      // Save recent predictions (keep only last 2)
      List recent = box.read("recent_predictions") ?? [];
      // Add new prediction to the start
      recent.insert(0, requestBody);
      // Remove duplicates (by year, rank, state, category, course, quota, etc.)
      final seen = <String>{};
      recent = recent.where((p) {
        final key =
            "${p['year']}_${p['rank']}_${p['state']}_${p['category']}_${p['course']}_${p['quota']}";
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      // Keep only the last 2
      if (recent.length > 2) recent = recent.sublist(0, 2);
      box.write("recent_predictions", recent);
      recentPredictions.assignAll(recent.whereType<Map<String, dynamic>>());

      /// Get recent predictions (returns List<Map>)

      /// ðŸ”¥ HANDLE PRIVATE FALLBACK
      // if (data.noChanceInHomeState) {
      //   AppSnackbar.show(
      //     "No Government College",
      //     "Showing Private College Suggestions",
      //     snackPosition: SnackPosition.BOTTOM,
      //   );
      // } else {
      //   AppSnackbar.show(
      //     "Success",
      //     "Government Colleges Found",
      //     snackPosition: SnackPosition.BOTTOM,
      //   );
      // }

      final elapsed = DateTime.now().difference(startedAt);
      final remainingDelay = minimumLoadingDuration - elapsed;
      if (!remainingDelay.isNegative && remainingDelay > Duration.zero) {
        await Future.delayed(remainingDelay);
      }

      /// Navigate AFTER data is ready
      Get.to(() => AiPredictionResultView(predictionData: data));
    } on AppException catch (e) {
      print("Prediction Error: $e");

      errorMessage.value = e.message;

      AppSnackbar.show("Error", e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("Prediction Error: $e");

      errorMessage.value = "Prediction failed";

      AppSnackbar.show(
        "Error",
        "Unable to fetch prediction",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPredictionLoading.value = false;
    }
  }

  List<Map<String, dynamic>> getRecentPredictions() {
    return recentPredictions.toList();
  }

  Future<void> loadMasters({
    bool showGlobalNetworkError = false,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await RegisterMasterApi().fetchMasters(
        showGlobalNetworkError: showGlobalNetworkError,
        forceRefresh: forceRefresh,
      );

      /// State dropdown should come from statewise-availability only.
      categoryList.value = data['categories'];

      /// Courses dropdown should come from backend masters based on user profile.
      List<CourseModel> fetchedCourses = [];
      if (profileController.isUGUser) {
        fetchedCourses = data['courses_for_ug'] as List<CourseModel>? ?? [];
      } else {
        final pgCourses = data['courses']?['PG'] as Map<String, dynamic>? ?? {};
        for (final level in pgCourses.values) {
          if (level is List) {
            fetchedCourses.addAll(level.whereType<CourseModel>());
          }
        }
      }
      courseList.assignAll(fetchedCourses);
      statewisePgCourses.value =
          data['statewise_courses_for_pg'] as Map<String, List<CourseModel>>? ??
          {};

      /// Keep profile-selected course when valid; otherwise fallback to first.
      final hasSelectedCourse = currentAvailableCourses.any(
        (course) => course.name == selectedCourse.value,
      );
      if (!hasSelectedCourse) {
        selectedCourse.value = currentAvailableCourses.isNotEmpty
            ? currentAvailableCourses.first.name
            : "";
      }
    } on AppException catch (e) {
      AppSnackbar.show("Error", e.message);
    } catch (e) {
      AppSnackbar.show("Error", "Failed to load master data");
    }
  }

  void goToPremium() {
    Get.toNamed(AppRoutes.subscription);
  }

  void setSelectedRound(String value) {
    final round = roundsList.firstWhere((e) => e.roundName == value);

    selectedRound.value = round.roundName;
    selectedRoundId.value = round.id; // ðŸ”¥ important
  }
}
