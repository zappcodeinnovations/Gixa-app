import 'package:Gixa/services/compare_history_service.dart';
import 'package:get/get.dart';
import '../model/compare_history_model.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class CompareHistoryController extends GetxController {
  final isLoading = false.obs;
  final historyList = <CompareHistoryItem>[].obs;

  // Selection logic
  final isSelectionMode = false.obs;
  final selectedIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      isLoading.value = true;
      final response = await CompareHistoryService.fetchHistory();
      historyList.assignAll(response.history);
    } catch (e) {
      AppSnackbar.show("Error", "Failed to load comparison history");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedIds.clear();
    }
  }

  void toggleSelection(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;

    try {
      isLoading.value = true;
      for (final id in selectedIds) {
        await CompareHistoryService.deleteHistory(id);
      }
      AppSnackbar.show("Success", "Selected history deleted");
      selectedIds.clear();
      isSelectionMode.value = false;
      await fetchHistory();
    } catch (e) {
      AppSnackbar.show("Error", "Failed to delete history");
    } finally {
      isLoading.value = false;
    }
  }
}

