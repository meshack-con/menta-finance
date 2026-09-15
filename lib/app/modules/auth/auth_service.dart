import '../../core/network/api_client.dart';
import './models/user_model.dart';

class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  /// Inapiga POST /api/login (backend inarudisha {"token", "token_type", "user"})
  Future<({String token, UserModel user})> login({
    required String username,
    required String password,
  }) async {
    final data = await _api.post(
      '/api/login',
      body: {'username': username, 'password': password},
      auth: false,
    );
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }
}
