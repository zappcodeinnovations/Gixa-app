import 'package:Gixa/Modules/CollageDetails/model/college_cutoff_model.dart';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/CollageDetails/controller/collage_detail_controller.dart';
import 'package:Gixa/network/app_exception.dart';
import 'package:Gixa/services/college_api_service.dart';
import 'package:get/get.dart';

class CollegeCutoffController extends GetxController {
  final int collegeId;

  CollegeCutoffController({required this.collegeId});

  final CollegeApiService _service = CollegeApiService();
  late final ProfileController _profileController;
  final selectedRecordsRx = <CollegeCategoryCutoffRecord>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final userAir = 0.obs;
  final cutoffData = Rxn<CollegeCategoryCutoffResponse>();
  final selectedCourseId = RxnInt();
  final selectedSpecialityType = RxnString();
  final selectedSpecialityId = RxnInt();
  final selectedQuotaId = RxnInt();

  @override
  Future<void> onInit() async {
    super.onInit();
    _profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    await loadCutoffs();
  }

  void _updateSelectedRecords() {
    var records = _filteredRecordsBeforeQuota();

    if (selectedQuotaId.value != null) {
      records = records
          .where((record) => record.quotaId == selectedQuotaId.value)
          .toList();
    }

    records.sort((a, b) {
      if (a.eligible != b.eligible) {
        return a.eligible ? -1 : 1;
      }
      final gapCompare = a.rankDifference.abs().compareTo(
        b.rankDifference.abs(),
      );
      if (gapCompare != 0) {
        return gapCompare;
      }
      return a.lastCutoffRank.compareTo(b.lastCutoffRank);
    });

    selectedRecordsRx.assignAll(records);
  }

  Future<void> loadCutoffs({bool forceRefresh = false}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _profileController.ensureLoaded(force: forceRefresh);
      userAir.value = _profileController.profile.value?.allIndiaRank ?? 0;

      if (userAir.value <= 0) {
        cutoffData.value = null;
        errorMessage.value = '';
        return;
      }

      final result = await _service.fetchCollegeCategoryCutoffs(
        collegeId,
        allIndiaRank: userAir.value,
        forceRefresh: forceRefresh,
      );

      cutoffData.value = result;
      _seedFilters();
      _updateSelectedRecords();
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Unable to load cutoff data right now.';
    } finally {
      isLoading.value = false;
    }
  }

  bool get needsAir => userAir.value <= 0;

  bool _isCourseRecordUG(CollegeCategoryCutoffRecord record) {
    if (_profileController.isCourseUG(record.courseId)) return true;
    
    final name = record.courseName.trim().toUpperCase();
    if (['MBBS', 'BDS', 'BAMS', 'BHMS', 'BUMS', 'BSMS'].contains(name)) {
      return true;
    }
    
    for (final c in _profileController.ugCourseList) {
      if (c.name.trim().toUpperCase() == name) return true;
    }
    
    return false;
  }

  List<MapEntry<int, String>> get courseOptions {
    final map = <int, String>{};
    final isUGUser = _profileController.isUGUser;
    
    for (final record in cutoffData.value?.categoryCutoffs ?? const <CollegeCategoryCutoffRecord>[]) {
      final isCourseUG = _isCourseRecordUG(record);
      if (isUGUser == isCourseUG) {
        map[record.courseId] = record.courseName;
      }
    }
    return map.entries.toList();
  }

  List<MapEntry<String, String>> get specialityTypeOptions {
    final map = <String, String>{};
    var records = cutoffData.value?.categoryCutoffs ?? const <CollegeCategoryCutoffRecord>[];
    if (selectedCourseId.value != null) {
      records = records.where((r) => r.courseId == selectedCourseId.value).toList();
    }

    for (final record in records) {
      if (record.specialityType != null && record.specialityType!.trim().isNotEmpty && record.specialityType!.toLowerCase() != 'null') {
        map[record.specialityType!] = record.specialityType!;
      }
    }
    return map.entries.toList();
  }

  List<MapEntry<int, String>> get specialityOptions {
    final map = <int, String>{};
    var records = cutoffData.value?.categoryCutoffs ?? const <CollegeCategoryCutoffRecord>[];
    if (selectedCourseId.value != null) {
      records = records.where((r) => r.courseId == selectedCourseId.value).toList();
    }
    if (selectedSpecialityType.value != null) {
      records = records.where((r) => r.specialityType == selectedSpecialityType.value).toList();
    }

    for (final record in records) {
      if (record.specialityId != null && record.specialityName != null && record.specialityName!.trim().isNotEmpty && record.specialityName!.toLowerCase() != 'null') {
        map[record.specialityId!] = record.specialityName!;
      }
    }
    return map.entries.toList();
  }

  List<MapEntry<int, String>> get quotaOptions {
    final map = <int, String>{};
    for (final record in _filteredRecordsBeforeQuota()) {
      map[record.quotaId] = record.quotaName;
    }
    return map.entries.toList();
  }

  List<CollegeCategoryCutoffRecord> get selectedRecords {
    var records = _filteredRecordsBeforeQuota();

    if (selectedQuotaId.value != null) {
      records = records
          .where((record) => record.quotaId == selectedQuotaId.value)
          .toList();
    }

    records.sort((a, b) {
      if (a.eligible != b.eligible) {
        return a.eligible ? -1 : 1;
      }
      final gapCompare = a.rankDifference.abs().compareTo(
        b.rankDifference.abs(),
      );
      if (gapCompare != 0) {
        return gapCompare;
      }
      return a.lastCutoffRank.compareTo(b.lastCutoffRank);
    });
    return records;
  }

  List<CollegeCategoryCutoffRecord> get eligibleRecords =>
      selectedRecordsRx.where((record) => record.eligible).toList();

  List<CollegeCategoryCutoffRecord> get userMatchedRecords =>
      selectedRecordsRx.where(isUserCategoryMatch).toList();

  String get userCategoryLabel {
    final profile = _profileController.profile.value;
    final parts = <String>[];

    void add(String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty || parts.contains(text)) {
        return;
      }
      parts.add(text);
    }

    add(profile?.category);
    for (final value in profile?.horizontals ?? const <String>[]) {
      add(value);
    }

    return parts.isEmpty ? 'Not added in profile' : parts.join(' / ');
  }

  String get headlineMessage {
    if (needsAir) {
      return 'Add your AIR in profile to unlock college-wise cutoff guidance.';
    }

    final records = selectedRecordsRx;
    if (records.isEmpty) {
      return 'No cutoff records are available for the selected filters yet.';
    }

    final eligible = eligibleRecords;
    final courseName = records.first.courseName;
    final quotaName = records.first.quotaName;
    final airText = formatNumber(userAir.value);

    if (eligible.isEmpty) {
      return 'Your AIR of $airText does not clear the displayed categories for $courseName under $quotaName yet.';
    }

    final bestMatches = eligible
        .take(3)
        .map((e) => e.displayCategory)
        .join(', ');
    if (eligible.length == records.length) {
      return 'Your AIR of $airText clears all ${records.length} displayed categories for $courseName under $quotaName.';
    }

    return 'Your AIR of $airText clears ${eligible.length} of ${records.length} displayed categories for $courseName under $quotaName. Best matches: $bestMatches.';
  }

  String get subMessage {
    final records = selectedRecordsRx;
    if (records.isEmpty) {
      return 'Try another course or quota if available.';
    }

    final closest = records.reduce((current, next) {
      final currentGap = current.rankDifference.abs();
      final nextGap = next.rankDifference.abs();
      return nextGap < currentGap ? next : current;
    });

    final gap = closest.rankDifference.abs();
    final gapText = formatNumber(gap);
    final relation = closest.eligible ? 'ahead by' : 'short by';

    return 'Closest category: ${closest.displayCategory} with cutoff ${formatNumber(closest.lastCutoffRank)}. You are $relation $gapText ranks.';
  }

  void updateCourse(int? courseId) {
    selectedCourseId.value = courseId;
    
    final types = specialityTypeOptions;
    selectedSpecialityType.value = types.isEmpty ? null : types.first.key;
    
    final specialities = specialityOptions;
    selectedSpecialityId.value = specialities.isEmpty ? null : specialities.first.key;
    
    final quotas = quotaOptions;
    selectedQuotaId.value = quotas.isEmpty ? null : quotas.first.key;

    _updateSelectedRecords();
  }

  void updateSpecialityType(String? type) {
    selectedSpecialityType.value = type;
    
    final specialities = specialityOptions;
    selectedSpecialityId.value = specialities.isEmpty ? null : specialities.first.key;
    
    final quotas = quotaOptions;
    selectedQuotaId.value = quotas.isEmpty ? null : quotas.first.key;

    _updateSelectedRecords();
  }

  void updateSpeciality(int? specialityId) {
    selectedSpecialityId.value = specialityId;
    
    final quotas = quotaOptions;
    selectedQuotaId.value = quotas.isEmpty ? null : quotas.first.key;

    _updateSelectedRecords();
  }

  void updateQuota(int? quotaId) {
    selectedQuotaId.value = quotaId;
    _updateSelectedRecords();
  }

  bool isUserCategoryMatch(CollegeCategoryCutoffRecord record) {
    final profile = _profileController.profile.value;
    if (profile == null) {
      return false;
    }

    final userTokens = <String>{
      ..._categoryTokens(profile.category),
      for (final value in profile.horizontals ?? const <String>[])
        ..._categoryTokens(value),
    };

    if (userTokens.isEmpty) {
      return false;
    }

    final recordTokens = <String>{
      ..._categoryTokens(record.category),
      ..._categoryTokens(record.mainCategory),
      ..._categoryTokens(record.allotmentCategory),
      ..._categoryTokens(record.horizontalReservation),
      ..._categoryTokens(record.displayCategory),
    };

    return userTokens.any(recordTokens.contains);
  }

  String formatNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final positionFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  void _seedFilters() {
    final courses = courseOptions;
    if (courses.isEmpty) {
      selectedCourseId.value = null;
      selectedSpecialityType.value = null;
      selectedSpecialityId.value = null;
      selectedQuotaId.value = null;
      return;
    }

    selectedCourseId.value ??= courses.first.key;
    
    if (!_profileController.isUGUser) {
      final types = specialityTypeOptions;
      if (selectedSpecialityType.value == null && types.isNotEmpty) {
        selectedSpecialityType.value = types.first.key;
      }
      
      final specialities = specialityOptions;
      if (selectedSpecialityId.value == null && specialities.isNotEmpty) {
        selectedSpecialityId.value = specialities.first.key;
      }
    }

    final quotas = quotaOptions;
    if (selectedQuotaId.value == null && quotas.isNotEmpty) {
      selectedQuotaId.value = quotas.first.key;
    }
  }

  List<CollegeCategoryCutoffRecord> _filteredRecordsBeforeQuota() {
    var records =
        cutoffData.value?.categoryCutoffs ??
        const <CollegeCategoryCutoffRecord>[];

    final isUGUser = _profileController.isUGUser;
    records = records.where((r) => _isCourseRecordUG(r) == isUGUser).toList();

    if (selectedCourseId.value != null) {
      records = records
          .where((record) => record.courseId == selectedCourseId.value)
          .toList();
    }
    
    if (!isUGUser) {
      if (selectedSpecialityType.value != null) {
        records = records
            .where((record) => record.specialityType == selectedSpecialityType.value)
            .toList();
      }
      if (selectedSpecialityId.value != null) {
        records = records
            .where((record) => record.specialityId == selectedSpecialityId.value)
            .toList();
      }
    }

    return List<CollegeCategoryCutoffRecord>.from(records);
  }

  Set<String> _categoryTokens(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return const <String>{};
    }

    return raw
        .split(RegExp(r'[|/,()]'))
        .map(_normalizeToken)
        .where((token) => token.isNotEmpty)
        .toSet();
  }

  String _normalizeToken(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
