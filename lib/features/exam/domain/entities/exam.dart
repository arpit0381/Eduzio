class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  const QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['question_text'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correct_option_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_text': questionText,
      'options': options,
      'correct_option_index': correctOptionIndex,
    };
  }
}

class Quiz {
  final String id;
  final String organizationId;
  final String batchId;
  final String? batchName;
  final String title;
  final String? description;
  final int durationMinutes;
  final List<QuizQuestion> questions;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Quiz({
    required this.id,
    required this.organizationId,
    required this.batchId,
    this.batchName,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.questions,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Quiz copyWith({
    String? id,
    String? organizationId,
    String? batchId,
    String? batchName,
    String? title,
    String? description,
    int? durationMinutes,
    List<QuizQuestion>? questions,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      questions: questions ?? this.questions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String studentId;
  final String? studentName;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });
}
