enum HomeworkStatus { pending, submitted, graded }

extension HomeworkStatusExt on HomeworkStatus {
  String get key {
    switch (this) {
      case HomeworkStatus.pending:
        return 'pending';
      case HomeworkStatus.submitted:
        return 'submitted';
      case HomeworkStatus.graded:
        return 'graded';
    }
  }

  String get label {
    switch (this) {
      case HomeworkStatus.pending:
        return 'Pending';
      case HomeworkStatus.submitted:
        return 'Submitted';
      case HomeworkStatus.graded:
        return 'Graded';
    }
  }

  static HomeworkStatus fromKey(String key) {
    switch (key) {
      case 'submitted':
        return HomeworkStatus.submitted;
      case 'graded':
        return HomeworkStatus.graded;
      default:
        return HomeworkStatus.pending;
    }
  }
}

class Homework {
  final String id;
  final String organizationId;
  final String batchId;
  final String? subjectId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String? fileUrl;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Homework({
    required this.id,
    required this.organizationId,
    required this.batchId,
    this.subjectId,
    required this.title,
    this.description,
    required this.dueDate,
    this.fileUrl,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Homework copyWith({
    String? id,
    String? organizationId,
    String? batchId,
    String? subjectId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? fileUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Homework(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      batchId: batchId ?? this.batchId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      fileUrl: fileUrl ?? this.fileUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
