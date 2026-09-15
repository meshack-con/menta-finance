import '../../core/network/api_client.dart';
import 'models/stakeholder_model.dart';

class StakeholdersService {
  final ApiClient _api;
  StakeholdersService(this._api);

  Future<List<StakeholderModel>> list({String? kind, String? q}) async {
    final data = await _api.get('/api/stakeholders/', query: {
      'limit': 200,
      if (kind != null) 'kind': kind,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (data as List).map((e) => StakeholderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StakeholderModel> create(StakeholderModel item) async {
    final data = await _api.post('/api/stakeholders/', body: item.toJson());
    return StakeholderModel.fromJson(data as Map<String, dynamic>);
  }

  Future<StakeholderModel> update(int id, StakeholderModel item) async {
    final data = await _api.put('/api/stakeholders/$id', body: item.toJson());
    return StakeholderModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/stakeholders/$id');
}
