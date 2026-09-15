class AdminOpportunityModel {
  final int id;
  final String title;
  final int categoryId;
  final int? rulerId;
  final String? authorName;
  final String? location;
  final DateTime? deadline;
  final int interestedCount;
  final bool isBlocked;
  final bool isApproved;
  final DateTime createdAt;

  AdminOpportunityModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.rulerId,
    this.authorName,
    this.location,
    this.deadline,
    required this.interestedCount,
    required this.isBlocked,
    required this.isApproved,
    required this.createdAt,
  });

  factory AdminOpportunityModel.fromJson(Map<String, dynamic> j) {
    return AdminOpportunityModel(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      categoryId: j['category_id'] as int,
      rulerId: j['ruler_id'] as int?,
      authorName: j['author_name'] as String?,
      location: j['location'] as String?,
      deadline: j['deadline'] != null ? DateTime.tryParse(j['deadline'] as String) : null,
      interestedCount: j['interested_count'] as int? ?? 0,
      isBlocked: j['is_blocked'] as bool? ?? false,
      isApproved: j['is_approved'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
