import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';
import 'package:Gixa/common/api.dart';
import 'package:Gixa/Modules/predication/model/state_category_model.dart';

class StateCategoryApiService {
  StateCategoryApiService._();

  static Future<Map<String, dynamic>> getStateCategories({
    List<String>? states,
    int? courseId,
    int? specialtyId,
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

      if (specialtyId != null) {
        queryParams['specialty_id'] = specialtyId.toString();
      }

      final uri = Uri.parse(ApiEndpoints.statewiseAvailability);
      final endpoint = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      }).toString();

      final fullUrl = endpoint.startsWith('http')
          ? endpoint
          : '${ApiConstants.baseUrl}$endpoint';
      print("🌐 FULL API URL FOR SELECT QUOTA => $fullUrl");

      final response = await ApiClient.get(
        endpoint,
        showGlobalNetworkError: showGlobalNetworkError,
        requestPolicy: RequestPolicy(
          ttl: const Duration(minutes: 5),
          forceRefresh: forceRefresh,
        ),
      );

      print("📥 SELECT QUOTA API RESPONSE => $response");

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
