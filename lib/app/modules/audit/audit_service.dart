import '../../core/network/api_client.dart';
import 'models/audit_log_model.dart';

class AuditService {
  final ApiClient _api;
  AuditService(this._api);

  Future<List<AuditLogModel>> list({int skip = 0, int limit = 200, String? entityType, String? action}) async {
    final data = await _api.get('/api/audit-logs/', query: {
      'skip': skip,
      'limit': limit,
      if (entityType != null) 'entity_type': entityType,
      if (action != null) 'action': action,
    });
    return (data as List).map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
