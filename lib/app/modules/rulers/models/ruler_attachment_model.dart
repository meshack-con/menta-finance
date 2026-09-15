class RulerAttachmentModel {
  final int id;
  final String? attachmentName;
  final String? description;

  RulerAttachmentModel({required this.id, this.attachmentName, this.description});

  factory RulerAttachmentModel.fromJson(Map<String, dynamic> j) {
    return RulerAttachmentModel(
      id: j['id'] as int,
      attachmentName: j['attachment_name'] as String?,
      description: j['description'] as String?,
    );
  }
}
