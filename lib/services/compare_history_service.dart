import 'package:Gixa/Modules/comparison/model/compare_history_model.dart';
import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';

class CompareHistoryService {
  static Future<CompareHistoryResponse> fetchHistory() async {
    final response = await ApiClient.get(ApiEndpoints.compareHistory);

    return CompareHistoryResponse.fromJson(response as Map<String, dynamic>);
  }

  static Future<void> deleteHistory(int historyId) async {
    await ApiClient.delete(
      ApiEndpoints.deleteCompareHistory,
      {'history_id': historyId},
    );
  }
}
