import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/auth_session.dart';
import '../../../core/storage/session_storage.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;
  bool isLoading = false;
  bool initialized = false;
  String? token;
  UserModel? user;
  String? error;

  bool get isAuthorized => token != null && token!.isNotEmpty;

  Future<void> init() async {
    token = await SessionStorage.readToken();
    AuthSession.token = token;
    initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _authenticate(() => _repository.login(email: email, password: password));
  }

  Future<bool> register(String name, String email, String password) async {
    return _authenticate(
      () => _repository.register(name: name, email: email, password: password),
    );
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    token = null;
    AuthSession.token = null;
    user = null;
    await SessionStorage.clearToken();
    notifyListeners();
  }

  Future<bool> _authenticate(Future<AuthResult> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      token = result.token;
      AuthSession.token = result.token;
      user = result.user;
      await SessionStorage.saveToken(result.token);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
