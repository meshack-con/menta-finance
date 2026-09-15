import '../../core/network/api_client.dart';
import 'models/admin_opportunity_model.dart';
import 'models/admin_topic_model.dart';

class ForumContentService {
  final ApiClient _api;
  ForumContentService(this._api);

  Future<List<AdminTopicModel>> listTopics({String? q}) async {
    final data = await _api.get('/api/admin/forum-moderation/topics', query: {
      'limit': 200,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (data as List).map((e) => AdminTopicModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminOpportunityModel>> listOpportunities({String? q}) async {
    final data = await _api.get('/api/admin/forum-moderation/opportunities', query: {
      'limit': 200,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (data as List).map((e) => AdminOpportunityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> blockTopic(int id) => _api.put('/api/admin/forum-moderation/topics/$id/block');
  Future<void> unblockTopic(int id) => _api.put('/api/admin/forum-moderation/topics/$id/unblock');
  Future<void> deleteTopic(int id) => _api.delete('/api/admin/forum-moderation/topics/$id');

  Future<void> blockOpportunity(int id) => _api.put('/api/admin/forum-moderation/opportunities/$id/block');
  Future<void> unblockOpportunity(int id) => _api.put('/api/admin/forum-moderation/opportunities/$id/unblock');
  Future<void> deleteOpportunity(int id) => _api.delete('/api/admin/forum-moderation/opportunities/$id');

  // ---------------- Uthibitisho wa Fursa (Approval) ----------------

  Future<void> approveOpportunity(int id) => _api.put('/api/admin/opportunities/$id/approve');

  Future<Map<String, dynamic>> resendNotifications(int id) async {
    final data = await _api.post('/api/admin/opportunities/$id/resend-notifications');
    return data as Map<String, dynamic>;
  }

  Future<void> createOpportunityAsAdmin({
    required String title,
    String? description,
    String? location,
    DateTime? deadline,
    String? requirements,
    String? contactLink,
    required int categoryId,
    List<int> occupationIds = const [],
  }) {
    return _api.post('/api/admin/opportunities/', body: {
      'title': title,
      'description': description,
      'location': location,
      'deadline': deadline == null
          ? null
          : '${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      'requirements': requirements,
      'contact_link': contactLink,
      'category_id': categoryId,
      'occupation_ids': occupationIds,
    });
  }

  Future<Map<String, dynamic>> getNotificationStats(int opportunityId) async {
    final data = await _api.get('/api/admin/opportunities/$opportunityId/notification-stats');
    return data as Map<String, dynamic>;
  }
}
