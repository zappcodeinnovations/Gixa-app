import 'package:Gixa/Modules/faq/model/faq_model.dart';
import 'package:Gixa/services/faq_api_service.dart';
import 'package:get/get.dart';

class FaqController extends GetxController {
  var isLoading = false.obs;
  var faqList = <FaqItem>[].obs;
  var visibleCount = 3.obs;

  Future<void> fetchFaqs({
    String search = "",
    int? page,
    bool forceRefresh = false,
  }) async {
    try {
      isLoading.value = true;
      print("🚀 [FaqController] fetchFaqs() started (search: '$search', page: $page, forceRefresh: $forceRefresh)");

      final response = await FaqApiService.getFaqs(
        search: search,
        page: page,
        forceRefresh: forceRefresh,
      );

      response.sort((a, b) => a.order.compareTo(b.order));
      faqList.value = response;

      print("📋 [FaqController] FAQs loaded successfully. Total count: ${faqList.length}");
      for (int i = 0; i < faqList.length; i++) {
        print("   🔹 [FAQ #${i + 1}] ID: ${faqList[i].id} | Order: ${faqList[i].order} | Question: ${faqList[i].question}");
      }
    } catch (e, stack) {
      print("❌ [FaqController ERROR]: $e");
      print("❌ [FaqController STACKTRACE]: $stack");
    } finally {
      isLoading.value = false;
      print("🏁 [FaqController] fetchFaqs() completed. (isLoading: false, total items: ${faqList.length})");
    }
  }

  void loadMore() {
    visibleCount.value += 5;
    print("➕ [FaqController] loadMore() triggered -> visibleCount: ${visibleCount.value}, total FAQs: ${faqList.length}, hasMore: $hasMore");
  }

  void showLess() {
    visibleCount.value = 3;
    print("➖ [FaqController] showLess() triggered -> visibleCount reset to: ${visibleCount.value}");
  }

  bool get hasMore => visibleCount.value < faqList.length;

  List<FaqItem> get displayedFaqs {
    if (faqList.isEmpty) return [];
    return faqList.take(visibleCount.value).toList();
  }
}

