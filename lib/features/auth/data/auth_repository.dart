import '../../../core/network/api_client.dart';
import 'user_model.dart';

class AuthResult {
  AuthResult({required this.token, required this.user});
  final String token;
  final UserModel user;
}

class AuthRepository {
  AuthRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    return AuthResult(
      token: response['token']?.toString() ?? '',
      user: UserModel.fromJson(response['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'locale': 'ru',
      'timezone': 'Asia/Qyzylorda',
      'default_currency': 'KZT',
    }) as Map<String, dynamic>;
    return AuthResult(
      token: response['token']?.toString() ?? '',
      user: UserModel.fromJson(response['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Future<void> logout() async {
    await _apiClient.post('/logout');
  }
}
