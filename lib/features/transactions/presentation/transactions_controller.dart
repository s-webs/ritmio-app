import 'package:flutter/foundation.dart';

import '../data/transaction_model.dart';
import '../data/transactions_repository.dart';

class TransactionsController extends ChangeNotifier {
  TransactionsController(this._repository);
  final TransactionsRepository _repository;

  bool isLoading = false;
  String? error;
  List<TransactionModel> items = [];

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

  Future<void> confirm(int id) async {
    await _repository.confirm(id);
    await load();
  }
}
