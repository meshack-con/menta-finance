class LeadershipModel {
  final int? id;
  final String name;
  final int? number;
  final String? section;
  final int titleId;
  final bool isBlocked;

  LeadershipModel({
    this.id,
    required this.name,
    this.number,
    this.section,
    required this.titleId,
    this.isBlocked = false,
  });

  factory LeadershipModel.fromJson(Map<String, dynamic> j) {
    return LeadershipModel(
      id: j['id'] as int?,
      name: j['name'] as String? ?? '',
      number: j['number'] as int?,
      section: j['section'] as String?,
      titleId: j['title_id'] as int,
      isBlocked: j['is_blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'section': section,
        'title_id': titleId,
      };
}
