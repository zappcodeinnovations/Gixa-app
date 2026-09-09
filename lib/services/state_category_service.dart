import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';
import 'package:Gixa/Modules/predication/model/state_category_model.dart';

class StateCategoryApiService {
  StateCategoryApiService._();

  static Future<Map<String, dynamic>> getStateCategories({
    List<String>? states,
    int? courseId,
    bool showGlobalNetworkError = true,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, String>{};

      final requestedStates = (states ?? const <String>[])
          .map((state) => state.trim())
          .where((state) => state.isNotEmpty)
          .toList();

      if (requestedStates.isNotEmpty) {
        if (requestedStates.length == 1) {
          queryParams['state'] = requestedStates[0];
        } else {
          queryParams['states'] = requestedStates.join(",");
        }
      }

      if (courseId != null) {
        queryParams['course_id'] = courseId.toString();
      }

      final uri = Uri.parse(ApiEndpoints.statewiseAvailability);
      final endpoint = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      }).toString();

      final response = await ApiClient.get(
        endpoint,
        showGlobalNetworkError: showGlobalNetworkError,
        requestPolicy: RequestPolicy(
          ttl: const Duration(minutes: 5),
          forceRefresh: forceRefresh,
        ),
      );

      print("📥 Statewise Categories Response: $response");

      if (response['success'] == true) {
        final List data = response['data'] ?? [];
        final categories = data
            .whereType<Map<String, dynamic>>()
            .map(StateCategoryModel.fromJson)
            .toList();

        return {
          'categories': categories,
          'selected_courses': response['selected_courses'] ?? [],
        };
      }

      return {};
    } catch (e) {
      print("❌ StateCategoryApi Error: $e");
      return {};
    }
  }
}
