import '../../../core/network/api_client.dart';
import 'category_model.dart';

class CategoriesRepository {
  CategoriesRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<CategoryModel>> list() async {
    final response = await _apiClient.get('/categories') as Map<String, dynamic>;
    final data = (response['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return data.map(CategoryModel.fromJson).toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _apiClient.post('/categories', body: body);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _apiClient.patch('/categories/$id', body: body);
  }

  Future<void> delete(int id) async {
    await _apiClient.delete('/categories/$id');
  }
}
