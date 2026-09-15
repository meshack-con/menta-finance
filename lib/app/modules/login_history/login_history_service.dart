import '../../core/network/api_client.dart';
import 'models/login_history_model.dart';

class LoginHistoryService {
  final ApiClient _api;
  LoginHistoryService(this._api);

  Future<List<LoginHistoryModel>> list({int skip = 0, int limit = 200}) async {
    final data = await _api.get('/api/login-history/', query: {'skip': skip, 'limit': limit});
    return (data as List).map((e) => LoginHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
