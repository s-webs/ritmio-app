import 'package:flutter/foundation.dart';

import '../data/categories_repository.dart';
import '../data/category_model.dart';

class CategoriesController extends ChangeNotifier {
  CategoriesController(this._repository);
  final CategoriesRepository _repository;

  bool isLoading = false;
  String? error;
  List<CategoryModel> items = [];

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
}
