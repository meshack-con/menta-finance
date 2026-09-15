import '../../core/network/api_client.dart';
import 'models/forum_category_model.dart';

class ForumCategoriesService {
  final ApiClient _api;
  ForumCategoriesService(this._api);

  Future<List<ForumCategoryModel>> list({String? kind}) async {
    final data = await _api.get('/api/admin/forum-categories/', query: {if (kind != null) 'kind': kind});
    return (data as List).map((e) => ForumCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ForumCategoryModel> create(ForumCategoryModel item) async {
    final data = await _api.post('/api/admin/forum-categories/', body: item.toJson());
    return ForumCategoryModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ForumCategoryModel> update(int id, ForumCategoryModel item) async {
    final data = await _api.put('/api/admin/forum-categories/$id', body: item.toJson());
    return ForumCategoryModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/admin/forum-categories/$id');
}
