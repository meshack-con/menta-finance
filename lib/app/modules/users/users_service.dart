import '../../core/network/api_client.dart';
import '../auth/models/user_model.dart';

class UsersService {
  final ApiClient _api;
  UsersService(this._api);

  Future<List<UserModel>> list({int skip = 0, int limit = 200}) async {
    final data = await _api.get('/api/users/', query: {'skip': skip, 'limit': limit});
    return (data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> create({
    required String username,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String roles = '',
  }) async {
    final data = await _api.post('/api/users/', body: {
      'username': username,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'roles': roles,
    }..removeWhere((k, v) => v == null));
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> update(
    int id, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? roles,
    int? active,
    bool? isBlocked,
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'roles': roles,
      'active': active,
      'is_blocked': isBlocked,
    }..removeWhere((k, v) => v == null);
    final data = await _api.put('/api/users/$id', body: body);
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changePassword(int id, {required String oldPassword, required String newPassword}) {
    return _api.put('/api/users/$id/change-password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  /// Admin anaweka password mpya kwa MTUMIAJI MWINGINE - hauitaji password ya zamani.
  Future<void> resetPassword(int id, {required String newPassword}) {
    return _api.put('/api/users/$id/reset-password', body: {
      'new_password': newPassword,
    });
  }

  Future<void> delete(int id) => _api.delete('/api/users/$id');
}
