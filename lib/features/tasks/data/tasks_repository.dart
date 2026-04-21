import '../../../core/network/api_client.dart';
import 'task_model.dart';

class TasksRepository {
  TasksRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<TaskModel>> list() async {
    final response = await _apiClient.get('/tasks') as Map<String, dynamic>;
    final data = (response['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return data.map(TaskModel.fromJson).toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _apiClient.post('/tasks', body: body);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _apiClient.patch('/tasks/$id', body: body);
  }

  Future<void> delete(int id) async {
    await _apiClient.delete('/tasks/$id');
  }

  Future<void> complete(int id) async {
    await _apiClient.post('/tasks/$id/complete');
  }

  Future<void> cancel(int id) async {
    await _apiClient.post('/tasks/$id/cancel');
  }
}
