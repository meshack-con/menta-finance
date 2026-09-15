/// Model ya jumla kwa entities "rahisi": jina + (hiari) FK ya "mzazi".
/// Inatumika kwa State/Region/District/Ward/Branch/Institute/
/// EducationLevel/EducationProgram/Title/Activity - zote zina muundo
/// sawa kwenye backend (id, name, [parent_id], is_blocked, created_at, updated_at).
class LookupItemModel {
  final int? id;
  final String name;
  final int? parentId;
  final bool isBlocked;

  LookupItemModel({this.id, required this.name, this.parentId, this.isBlocked = false});

  factory LookupItemModel.fromJson(Map<String, dynamic> j, {String? parentKey}) {
    return LookupItemModel(
      id: j['id'] as int?,
      name: j['name'] as String? ?? '',
      parentId: parentKey != null ? j[parentKey] as int? : null,
      isBlocked: j['is_blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson({String? parentKey}) {
    final map = <String, dynamic>{'name': name};
    if (parentKey != null) map[parentKey] = parentId;
    return map;
  }
}
