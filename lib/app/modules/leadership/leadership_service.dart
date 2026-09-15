import '../../core/network/api_client.dart';
import '../lookup/lookup_config.dart';
import '../lookup/lookup_service.dart';
import '../lookup/models/lookup_item_model.dart';
import 'models/leadership_model.dart';

class LeadershipService {
  final ApiClient _api;
  LeadershipService(this._api);

  Future<List<LeadershipModel>> list({int limit = 500}) async {
    final data = await _api.get('/api/leaderships/', query: {'limit': limit});
    return (data as List).map((e) => LeadershipModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Titles zinatumia moduli ya "lookup" iliyopo tayari (endpoint /api/titles)
  Future<List<LookupItemModel>> listTitles() {
    return LookupService(_api, titleEntityConfig.endpoint).list();
  }

  Future<LeadershipModel> create(LeadershipModel item) async {
    final data = await _api.post('/api/leaderships/', body: item.toJson());
    return LeadershipModel.fromJson(data as Map<String, dynamic>);
  }

  Future<LeadershipModel> update(int id, LeadershipModel item) async {
    final data = await _api.put('/api/leaderships/$id', body: item.toJson());
    return LeadershipModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/leaderships/$id');
}
