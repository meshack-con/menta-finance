import '../../core/network/api_client.dart';
import 'models/lookup_item_model.dart';

class LookupService {
  final ApiClient _api;
  final String endpoint;

  LookupService(this._api, this.endpoint);

  Future<List<LookupItemModel>> list({String? parentKey, int limit = 500}) async {
    final data = await _api.get('$endpoint/', query: {'limit': limit});
    return (data as List).map((e) => LookupItemModel.fromJson(e as Map<String, dynamic>, parentKey: parentKey)).toList();
  }

  Future<LookupItemModel> create(LookupItemModel item, {String? parentKey}) async {
    final data = await _api.post('$endpoint/', body: item.toJson(parentKey: parentKey));
    return LookupItemModel.fromJson(data as Map<String, dynamic>, parentKey: parentKey);
  }

  Future<LookupItemModel> update(int id, LookupItemModel item, {String? parentKey}) async {
    final data = await _api.put('$endpoint/$id', body: item.toJson(parentKey: parentKey));
    return LookupItemModel.fromJson(data as Map<String, dynamic>, parentKey: parentKey);
  }

  Future<void> delete(int id) => _api.delete('$endpoint/$id');
}
