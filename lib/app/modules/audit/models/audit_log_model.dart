class AuditLogModel {
  final int id;
  final int? userId;
  final String? username;
  final String action; // CREATE | UPDATE | DELETE
  final String entityType;
  final String? entityId;
  final String? description;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    this.userId,
    this.username,
    required this.action,
    required this.entityType,
    this.entityId,
    this.description,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> j) {
    return AuditLogModel(
      id: j['id'] as int,
      userId: j['user_id'] as int?,
      username: j['username'] as String?,
      action: j['action'] as String? ?? '',
      entityType: j['entity_type'] as String? ?? '',
      entityId: j['entity_id']?.toString(),
      description: j['description'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
