class ForumReportModel {
  final int id;
  final String entityType; // TOPIC | COMMENT | OPPORTUNITY
  final int entityId;
  final int rulerId;
  final String? reason;
  final DateTime createdAt;

  ForumReportModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.rulerId,
    this.reason,
    required this.createdAt,
  });

  factory ForumReportModel.fromJson(Map<String, dynamic> j) {
    return ForumReportModel(
      id: j['id'] as int,
      entityType: j['entity_type'] as String? ?? '',
      entityId: j['entity_id'] as int,
      rulerId: j['ruler_id'] as int,
      reason: j['reason'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
