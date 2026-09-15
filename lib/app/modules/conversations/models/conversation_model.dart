class ConversationModel {
  final int rulerId;
  final String rulerName;
  final String? membershipCode;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unreadCount;

  ConversationModel({
    required this.rulerId,
    required this.rulerName,
    this.membershipCode,
    this.lastMessage,
    this.lastAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) {
    return ConversationModel(
      rulerId: j['ruler_id'] as int,
      rulerName: j['ruler_name'] as String? ?? 'Mwanachama',
      membershipCode: j['membership_code'] as String?,
      lastMessage: j['last_message'] as String?,
      lastAt: j['last_at'] != null ? DateTime.tryParse(j['last_at'] as String) : null,
      unreadCount: j['unread_count'] as int? ?? 0,
    );
  }
}

class ConversationMessageModel {
  final int id;
  final int rulerId;
  final String sender; // MEMBER | ADMIN
  final String message;
  final bool isRead;
  final DateTime createdAt;

  ConversationMessageModel({
    required this.id,
    required this.rulerId,
    required this.sender,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ConversationMessageModel.fromJson(Map<String, dynamic> j) {
    return ConversationMessageModel(
      id: j['id'] as int,
      rulerId: j['ruler_id'] as int,
      sender: j['sender'] as String,
      message: j['message'] as String,
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
