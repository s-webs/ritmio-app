import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyController extends ChangeNotifier {
  CurrencyController() {
    _load();
  }

  static const _key = 'selected_currency';
  static const defaultCurrency = 'KZT';

  static const currencies = [
    _Currency('KZT', '₸', 'Казахстанский тенге'),
    _Currency('RUB', '₽', 'Российский рубль'),
    _Currency('USD', '\$', 'Доллар США'),
    _Currency('EUR', '€', 'Евро'),
  ];

  String _code = defaultCurrency;

  String get code => _code;
  String get symbol => currencies.firstWhere((c) => c.code == _code).symbol;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && currencies.any((c) => c.code == saved)) {
      _code = saved;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String code) async {
    if (_code == code) return;
    _code = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}

class _Currency {
  const _Currency(this.code, this.symbol, this.label);
  final String code;
  final String symbol;
  final String label;
}
