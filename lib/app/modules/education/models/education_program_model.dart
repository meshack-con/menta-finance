class EducationProgramModel {
  final int? id;
  final String name;
  final int? educationLevelId;
  EducationProgramModel({this.id, required this.name, this.educationLevelId});

  factory EducationProgramModel.fromJson(Map<String, dynamic> j) => EducationProgramModel(
        id: j['id'] as int?,
        name: j['name'] as String? ?? '',
        educationLevelId: j['education_level_id'] as int?,
      );

  Map<String, dynamic> toJson() => {'name': name, 'education_level_id': educationLevelId};
}
