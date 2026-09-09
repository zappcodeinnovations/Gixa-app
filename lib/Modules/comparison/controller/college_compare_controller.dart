import 'package:Gixa/Modules/comparison/model/college_compare_model.dart';
import 'package:Gixa/Modules/comparison/model/compare_history_model.dart';
import 'package:Gixa/Modules/comparison/model/save_compare_model.dart';
import 'package:Gixa/services/compare_collage_services.dart';
import 'package:Gixa/services/save_compare_service.dart';
import 'package:get/get.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class CollegeCompareController extends GetxController {
  final isLoading = false.obs;
  final isSaving = false.obs;

  final selectedColleges = <String>[].obs;
  final isSaved = false.obs;

  final compareResult = Rxn<CollegeCompareResponse>();

  SaveCompareResponse? lastSavedResult;

  @override
  void onInit() {
    super.onInit();
  }

  void initFromArgs(dynamic args) {
    // Reset previous state
    selectedColleges.clear();
    compareResult.value = null;
    lastSavedResult = null;
    isSaved.value = false;

    if (args == null) return;

    // From college list page: {'collegeCodes': ['101', '102']}
    if (args is Map && args['collegeCodes'] is List) {
      final rawCodes = args['collegeCodes'] as List;
      final codes = rawCodes
          .map<String>((code) => code.toString())
          .where((code) => code.isNotEmpty)
          .toList();
      if (codes.isNotEmpty) {
        selectedColleges.assignAll(codes);
        print('ðŸŸ¡ Loaded colleges from args ðŸ‘‰ $codes');
      }
    }

    // From history page: CompareHistoryItem
    if (args is CompareHistoryItem) {
      final codes = args.colleges
          .map((c) => c.collegeCode.toString())
          .where((code) => code.isNotEmpty)
          .toList();
      if (codes.isNotEmpty) {
        selectedColleges.assignAll(codes);
        print('ðŸŸ¡ Loaded colleges from history ðŸ‘‰ $codes');
      }
    }

    // Auto-compare if enough colleges
    if (selectedColleges.length >= 2) {
      compareColleges();
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ðŸ« TOGGLE COLLEGE SELECTION
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void toggleCollege(String code) {
    print('ðŸŸ¢ Toggle College ðŸ‘‰ $code');

    if (selectedColleges.contains(code)) {
      selectedColleges.remove(code);
    } else {
      if (selectedColleges.length < 2) {
        selectedColleges.add(code);
      } else {
        AppSnackbar.show(
          "Limit Reached",
          "Only 2 colleges can be compared at a time",
        );
      }
    }

    isSaved.value = false;
    print('🟩 Selected Colleges NOW 👉 $selectedColleges');
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ðŸ” COMPARE COLLEGES API
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> compareColleges() async {
    print('ðŸ”µ compareColleges() CALLED');
    print('ðŸ”µ Selected Colleges ðŸ‘‰ $selectedColleges');

    if (selectedColleges.length != 2) {
      AppSnackbar.show("Error", "Select exactly 2 colleges");
      return;
    }

    try {
      isLoading.value = true;
      isSaved.value = false;

      print('ðŸš€ Calling Compare API...');
      final result = await CollegeCompareService.compareColleges(
        selectedColleges,
      );

      print("===== COMPARE API RESPONSE =====");
      print("Status: ${result.status}");
      print("Total Colleges: ${result.totalColleges}");

      for (var college in result.comparison) {
        print("------------");
        print("College Name: ${college.collegeName}");
        print("College Code: ${college.collegeCode}");
        print("Total Seats: ${college.seats}");
        print("Cutoffs Count: ${college.cutoffs.length}");

        for (var cutoff in college.cutoffs) {
          print("Cutoff Seats: ${cutoff.totalSeats}");
        }
      }

      compareResult.value = result;
    } catch (e, stack) {
      print('âŒ Compare API FAILED');
      print('âŒ Error ðŸ‘‰ $e');
      print('âŒ Stack ðŸ‘‰ $stack');

      AppSnackbar.show("Error", "Failed to compare colleges");
    } finally {
      isLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ðŸ’¾ SAVE COMPARED COLLEGES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> saveComparedColleges() async {
    print('ðŸ’¾ Save Comparison CALLED');
    print('ðŸ’¾ Selected Colleges ðŸ‘‰ $selectedColleges');

    if (selectedColleges.isEmpty) {
      AppSnackbar.show("Error", "No colleges to save");
      return;
    }

    try {
      isSaving.value = true;

      final response = await SaveCompareService.saveComparison(
        selectedColleges,
      );

      lastSavedResult = response;

      print('âœ… Save API SUCCESS ðŸ‘‰ ${response.message}');

      AppSnackbar.show(
        "Saved Successfully",
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      print('âŒ Save API FAILED');
      print('âŒ Error ðŸ‘‰ $e');
      print('âŒ Stack ðŸ‘‰ $stack');

      AppSnackbar.show(
        "Error",
        "Failed to save comparison",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
      isSaved.value = true; 
    }
  }

  void loadHistoryComparison(dynamic historyItem) {
    compareResult.value = CollegeCompareResponse(
      status: "success",
      studentProfile: null,
      totalColleges: historyItem.colleges.length,
      comparison: historyItem.colleges,
    );
  }

  // ————————————————————————————————————————————
  // ♻️ CLEAR STATE
  // ————————————————————————————————————————————
  void clearComparison() {
    print('♻️ Clearing comparison state');
    selectedColleges.clear();
    compareResult.value = null;
    isSaved.value = false;
  }
}
