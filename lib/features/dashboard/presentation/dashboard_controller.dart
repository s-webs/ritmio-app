import 'package:flutter/foundation.dart';

import '../data/summary_model.dart';
import '../data/summary_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);
  final SummaryRepository _repository;

  bool isLoading = false;
  String? error;
  SummaryModel? weekly;
  SummaryModel? monthly;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      weekly = await _repository.weekly();
      monthly = await _repository.monthly();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
