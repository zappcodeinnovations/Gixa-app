import 'package:Gixa/Modules/faq/model/faq_model.dart';
import 'package:Gixa/services/faq_api_service.dart';
import 'package:get/get.dart';

class FaqController extends GetxController {
  var isLoading = false.obs;
  var faqList = <FaqItem>[].obs;
  var visibleCount = 3.obs;

  Future<void> fetchFaqs({
    String search = "",
    bool forceRefresh = false,
  }) async {
    try {
      isLoading.value = true;

      final response = await FaqApiService.getFaqs(
        search: search,
        forceRefresh: forceRefresh,
      );

      response.sort((a, b) => a.order.compareTo(b.order));
      faqList.value = response;
    } catch (e) {
      print("FAQ ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void loadMore() {
    visibleCount.value += 5;
  }

  void showLess() {
    visibleCount.value = 3;
  }

  bool get hasMore => visibleCount.value < faqList.length;

  List<FaqItem> get displayedFaqs {
    return faqList.take(visibleCount.value).toList();
  }
}
