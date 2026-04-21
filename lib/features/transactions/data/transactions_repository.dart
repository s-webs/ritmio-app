import '../../../core/network/api_client.dart';
import 'transaction_model.dart';

class TransactionsRepository {
  TransactionsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<TransactionModel>> list() async {
    final response = await _apiClient.get('/transactions') as Map<String, dynamic>;
    final data = (response['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return data.map(TransactionModel.fromJson).toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _apiClient.post('/transactions', body: body);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _apiClient.patch('/transactions/$id', body: body);
  }

  Future<void> delete(int id) async {
    await _apiClient.delete('/transactions/$id');
  }

  Future<void> confirm(int id) async {
    await _apiClient.post('/transactions/$id/confirm');
  }
}
