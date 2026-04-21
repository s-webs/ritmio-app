import '../../../core/network/api_client.dart';
import 'summary_model.dart';

class SummaryRepository {
  SummaryRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<SummaryModel> weekly() async {
    final response =
        await _apiClient.get('/finance/summary/weekly') as Map<String, dynamic>;
    return SummaryModel.fromJson(response);
  }

  Future<SummaryModel> monthly() async {
    final response =
        await _apiClient.get('/finance/summary/monthly') as Map<String, dynamic>;
    return SummaryModel.fromJson(response);
  }
}
