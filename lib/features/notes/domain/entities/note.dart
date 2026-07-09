class Note {
  final String id;
  final String organizationId;
  final String? batchId;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final String uploadedBy;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.organizationId,
    this.batchId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      batchId: json['batch_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'batch_id': batchId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'uploaded_by': uploadedBy,
    };
  }
}
