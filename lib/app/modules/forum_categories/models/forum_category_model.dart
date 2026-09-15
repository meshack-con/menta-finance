class ForumCategoryModel {
  final int? id;
  final String name;
  final String? icon;
  final String kind; // OPPORTUNITY | DISCUSSION
  final int sortOrder;
  final bool isBlocked;

  ForumCategoryModel({this.id, required this.name, this.icon, required this.kind, this.sortOrder = 0, this.isBlocked = false});

  factory ForumCategoryModel.fromJson(Map<String, dynamic> j) {
    return ForumCategoryModel(
      id: j['id'] as int?,
      name: j['name'] as String? ?? '',
      icon: j['icon'] as String?,
      kind: j['kind'] as String? ?? 'DISCUSSION',
      sortOrder: j['sort_order'] as int? ?? 0,
      isBlocked: j['is_blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon, 'kind': kind, 'sort_order': sortOrder};
}
