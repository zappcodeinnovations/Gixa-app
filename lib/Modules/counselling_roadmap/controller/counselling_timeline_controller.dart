import 'package:get/get.dart';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/counselling_roadmap/model/counselling_timeline_model.dart';
import 'package:Gixa/services/counselling_timeline_service.dart';

class CounsellingTimelineController extends GetxController {
  final ProfileController _profileController = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController(), permanent: true);

  final RxBool isLoading = false.obs;
  final RxString selectedRound = 'Round 1'.obs;
  final RxString selectedDateRound = 'All'.obs;
  final RxString currentStateCode = 'MH'.obs;

  final RxList<CounsellingDateEvent> dates = <CounsellingDateEvent>[].obs;
  final RxList<CounsellingTimelineStep> timelineSteps = <CounsellingTimelineStep>[].obs;
  final RxString currentRoundName = 'Round 1'.obs;

  List<String> get availableRounds => ['Round 1', 'Round 2', 'Mop-up'];
  List<String> get availableDateRounds => ['All', 'Round 1', 'Round 2', 'Mop-up'];

  bool get isUG => _profileController.isUGUser;

  @override
  void onInit() {
    super.onInit();
    _initStateAndFetch();
  }

  void _initStateAndFetch() {
    // Resolve state code from student profile (e.g. 'MH', 'UP', 'KA')
    final userState = _profileController.profile.value?.state?.trim();
    if (userState != null && userState.isNotEmpty) {
      currentStateCode.value = _stateNameToCode(userState);
    } else {
      currentStateCode.value = 'MH';
    }

    loadTimeline();
  }

  Future<void> loadTimeline({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      final type = isUG ? 'ug' : 'pg';
      final response = await CounsellingTimelineService.fetchTimeline(
        stateId: currentStateCode.value,
        type: type,
      );

      dates.assignAll(response.dates);
      timelineSteps.assignAll(response.timeline);
      currentRoundName.value = response.currentRound;

      if (!availableRounds.contains(selectedRound.value)) {
        selectedRound.value = 'Round 1';
      }
    } finally {
      isLoading.value = false;
    }
  }

  void selectRound(String round) {
    selectedRound.value = round;
  }

  void selectDateRound(String round) {
    selectedDateRound.value = round;
  }

  void changeState(String stateCode) {
    currentStateCode.value = stateCode.toUpperCase();
    loadTimeline(forceRefresh: true);
  }

  // Filtered dates by chosen round
  List<CounsellingDateEvent> get filteredDates {
    if (selectedDateRound.value == 'All') {
      return dates;
    }
    return dates
        .where((d) => d.round.toLowerCase() == selectedDateRound.value.toLowerCase())
        .toList();
  }

  // Filtered timeline steps by chosen round
  List<CounsellingTimelineStep> get filteredSteps {
    return timelineSteps
        .where((s) => s.round.toLowerCase() == selectedRound.value.toLowerCase())
        .toList();
  }

  // Current active step in the selected round
  CounsellingTimelineStep? get activeStep {
    return filteredSteps.firstWhereOrNull((s) => s.isActive) ??
        filteredSteps.firstWhereOrNull((s) => s.isCompleted);
  }

  int get completedStepsCount => filteredSteps.where((s) => s.isCompleted).length;

  static String _stateNameToCode(String stateName) {
    final lower = stateName.toLowerCase();
    if (lower.contains('maharashtra')) return 'MH';
    if (lower.contains('uttar pradesh')) return 'UP';
    if (lower.contains('madhya pradesh')) return 'MP';
    if (lower.contains('kerala')) return 'KL';
    if (lower.contains('gujarat')) return 'GJ';
    if (lower.contains('rajasthan')) return 'RJ';
    if (lower.contains('tamil')) return 'TN';
    if (lower.contains('jharkhand')) return 'JH';
    if (lower.contains('pondicherry') || lower.contains('puducherry')) return 'PY';
    if (lower.contains('karnataka')) return 'KA';
    if (lower.contains('mcc') || lower.contains('all india')) return 'AIQ';
    return stateName.length == 2 ? stateName.toUpperCase() : 'MH';
  }
}

