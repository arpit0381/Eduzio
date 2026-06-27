class Exam {
  final String id;
  final String organizationId;
  final String batchId;
  final String? subjectId;
  final String title;
  final String? description;
  final DateTime examDate;
  final int maxMarks;
  final int? passingMarks;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Exam({
    required this.id,
    required this.organizationId,
    required this.batchId,
    this.subjectId,
    required this.title,
    this.description,
    required this.examDate,
    required this.maxMarks,
    this.passingMarks,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Exam copyWith({
    String? id,
    String? organizationId,
    String? batchId,
    String? subjectId,
    String? title,
    String? description,
    DateTime? examDate,
    int? maxMarks,
    int? passingMarks,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exam(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      batchId: batchId ?? this.batchId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      examDate: examDate ?? this.examDate,
      maxMarks: maxMarks ?? this.maxMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ExamResult {
  final String id;
  final String examId;
  final String studentId;
  final int marksObtained;
  final String? remarks;
  final DateTime? createdAt;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.marksObtained,
    this.remarks,
    this.createdAt,
  });
}
