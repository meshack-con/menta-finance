import '../../core/network/api_client.dart';
import 'models/document_type_model.dart';

class DocumentTypesService {
  final ApiClient _api;
  DocumentTypesService(this._api);

  Future<List<DocumentTypeModel>> list() async {
    final data = await _api.get('/api/admin/document-types/');
    return (data as List).map((e) => DocumentTypeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DocumentTypeModel> create(DocumentTypeModel item) async {
    final data = await _api.post('/api/admin/document-types/', body: item.toJson());
    return DocumentTypeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<DocumentTypeModel> update(int id, DocumentTypeModel item) async {
    final data = await _api.put('/api/admin/document-types/$id', body: item.toJson());
    return DocumentTypeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/admin/document-types/$id');
}
