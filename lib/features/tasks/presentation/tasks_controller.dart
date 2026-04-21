import 'package:flutter/foundation.dart';

import '../data/task_model.dart';
import '../data/tasks_repository.dart';

class TasksController extends ChangeNotifier {
  TasksController(this._repository);
  final TasksRepository _repository;

  bool isLoading = false;
  String? error;
  List<TaskModel> items = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repository.list();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _repository.create(body);
    await load();
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _repository.update(id, body);
    await load();
  }

  Future<void> remove(int id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> complete(int id) async {
    await _repository.complete(id);
    await load();
  }

  Future<void> cancel(int id) async {
    await _repository.cancel(id);
    await load();
  }
}
