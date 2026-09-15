class EducationLevelModel {
  final int? id;
  final String name;
  final int? branchId;
  EducationLevelModel({this.id, required this.name, this.branchId});

  factory EducationLevelModel.fromJson(Map<String, dynamic> j) => EducationLevelModel(
        id: j['id'] as int?,
        name: j['name'] as String? ?? '',
        branchId: j['branch_id'] as int?,
      );

  Map<String, dynamic> toJson() => {'name': name, 'branch_id': branchId};
}
