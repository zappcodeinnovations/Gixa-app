import 'package:Gixa/Modules/faq/model/faq_model.dart';
import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';

class FaqApiService {
  FaqApiService._();

  /// 🔹 GET FAQ LIST
  static Future<List<FaqItem>> getFaqs({
    String search = "",
    int? page,
    bool forceRefresh = false,
  }) async {
    try {
      List<FaqItem> allFaqs = [];
      int currentPage = page ?? 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        print("📌 [FAQ API] Fetching FAQs -> Page: $currentPage, Search: '$search'");

        final response = await ApiClient.get(
          ApiEndpoints.faq,
          queryParameters: {
            if (search.isNotEmpty) "search": search,
            "page": currentPage,
          },
          requestPolicy: RequestPolicy(
            ttl: const Duration(minutes: 5),
            forceRefresh: forceRefresh,
          ),
        );

        print("🔥 [FAQ API] Response for Page $currentPage: $response");

        if (response == null) {
          print("⚠️ [FAQ API] Response is null for Page $currentPage. Stopping fetch.");
          break;
        }

        List rawList = [];

        if (response is List) {
          rawList = response;
        } else if (response is Map) {
          final data = response['data'];
          if (data is List) {
            rawList = data;
          } else if (data is Map) {
            if (data['faqs'] is List) {
              rawList = data['faqs'] as List;
            } else if (data['results'] is List) {
              rawList = data['results'] as List;
            } else if (data['data'] is List) {
              rawList = data['data'] as List;
            }
          } else if (response['faqs'] is List) {
            rawList = response['faqs'] as List;
          } else if (response['results'] is List) {
            rawList = response['results'] as List;
          }
        }

        final pageItems = rawList
            .where((e) => e != null && e is Map)
            .map((e) => FaqItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        print("📊 [FAQ API] Page $currentPage: Received ${pageItems.length} FAQs");

        allFaqs.addAll(pageItems);

        // If a specific page was explicitly passed, don't paginate through remaining pages
        if (page != null) {
          break;
        }

        // Pagination condition: If data count < 10, no need to increase page in API
        if (pageItems.length < 10) {
          print("🛑 [FAQ API] Page $currentPage data count (${pageItems.length}) is < 10. No need to increase page in API.");
          hasMorePages = false;
        } else {
          print("➡️ [FAQ API] Page $currentPage data count (${pageItems.length}) is >= 10. Increasing page from $currentPage to ${currentPage + 1} in API...");
          currentPage++;
        }
      }

      print("✅ [FAQ API] Total FAQs fetched: ${allFaqs.length}");
      return allFaqs;
    } catch (e, stackTrace) {
      print("❌ [FAQ API SERVICE ERROR]: $e");
      print("❌ [FAQ API STACKTRACE]: $stackTrace");
      return [];
    }
  }
}

