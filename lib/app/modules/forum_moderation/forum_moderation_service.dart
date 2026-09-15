import '../../core/network/api_client.dart';
import 'models/forum_report_model.dart';

class ForumModerationService {
  final ApiClient _api;
  ForumModerationService(this._api);

  Future<List<ForumReportModel>> listReports() async {
    final data = await _api.get('/api/admin/forum-reports/');
    return (data as List).map((e) => ForumReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteReport(int id) => _api.delete('/api/admin/forum-reports/$id');

  Future<void> blockTopic(int id) => _api.put('/api/admin/forum-moderation/topics/$id/block');
  Future<void> blockOpportunity(int id) => _api.put('/api/admin/forum-moderation/opportunities/$id/block');
}
