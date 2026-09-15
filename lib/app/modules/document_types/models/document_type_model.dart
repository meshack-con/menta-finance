class DocumentTypeModel {
  final int? id;
  final String name;
  final String? description;
  final bool isRequired;
  final int sortOrder;
  final bool isBlocked;

  DocumentTypeModel({
    this.id,
    required this.name,
    this.description,
    this.isRequired = false,
    this.sortOrder = 0,
    this.isBlocked = false,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> j) {
    return DocumentTypeModel(
      id: j['id'] as int?,
      name: j['name'] as String? ?? '',
      description: j['description'] as String?,
      isRequired: j['is_required'] as bool? ?? false,
      sortOrder: j['sort_order'] as int? ?? 0,
      isBlocked: j['is_blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'is_required': isRequired,
        'sort_order': sortOrder,
      };
}
