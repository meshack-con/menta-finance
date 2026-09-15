class AdminTopicModel {
  final int id;
  final String title;
  final int categoryId;
  final int rulerId;
  final String? authorName;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final double averageRating;
  final int ratingCount;
  final bool isBlocked;
  final DateTime createdAt;

  AdminTopicModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.rulerId,
    this.authorName,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.averageRating,
    required this.ratingCount,
    required this.isBlocked,
    required this.createdAt,
  });

  factory AdminTopicModel.fromJson(Map<String, dynamic> j) {
    return AdminTopicModel(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      categoryId: j['category_id'] as int,
      rulerId: j['ruler_id'] as int,
      authorName: j['author_name'] as String?,
      likeCount: j['like_count'] as int? ?? 0,
      commentCount: j['comment_count'] as int? ?? 0,
      viewCount: j['view_count'] as int? ?? 0,
      averageRating: (j['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: j['rating_count'] as int? ?? 0,
      isBlocked: j['is_blocked'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
