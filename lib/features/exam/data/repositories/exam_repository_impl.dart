import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exam_repository.dart';

class ExamRepositoryImpl implements ExamRepository {
  final SupabaseClient _client;

  ExamRepositoryImpl(this._client);

  @override
  Future<List<Quiz>> getQuizzes(String organizationId, {String? batchId}) async {
    var query = _client
        .from('quizzes')
        .select('*, batches:batch_id(name)');
    
    query = query.eq('organization_id', organizationId);
    
    if (batchId != null) {
      query = query.eq('batch_id', batchId);
    }
    
    final response = await query.order('created_at', ascending: false);
    
    return (response as List).map((json) {
      final jsonMap = json as Map<String, dynamic>;
      final batchData = jsonMap['batches'] as Map<String, dynamic>?;
      final batchName = batchData != null ? (batchData['name'] as String? ?? '') : '';
      
      final questionsList = (jsonMap['questions'] as List? ?? [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
          
      return Quiz(
        id: jsonMap['id'] as String,
        organizationId: jsonMap['organization_id'] as String,
        batchId: jsonMap['batch_id'] as String,
        batchName: batchName,
        title: jsonMap['title'] as String,
        description: jsonMap['description'] as String?,
        durationMinutes: jsonMap['duration_minutes'] as int? ?? 10,
        questions: questionsList,
        createdBy: jsonMap['created_by'] as String,
        createdAt: jsonMap['created_at'] != null ? DateTime.parse(jsonMap['created_at'] as String) : null,
        updatedAt: jsonMap['updated_at'] != null ? DateTime.parse(jsonMap['updated_at'] as String) : null,
      );
    }).toList();
  }

  @override
  Future<Quiz> createQuiz(Quiz quiz) async {
    final payload = {
      'organization_id': quiz.organizationId,
      'batch_id': quiz.batchId,
      'title': quiz.title,
      'description': quiz.description,
      'duration_minutes': quiz.durationMinutes,
      'questions': quiz.questions.map((q) => q.toJson()).toList(),
      'created_by': quiz.createdBy,
    };
    
    final response = await _client.from('quizzes').insert(payload).select('*, batches:batch_id(name)').single();
    
    final jsonMap = response;
    final batchData = jsonMap['batches'] as Map<String, dynamic>?;
    final batchName = batchData != null ? (batchData['name'] as String? ?? '') : '';
    
    final questionsList = (jsonMap['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
        
    return Quiz(
      id: jsonMap['id'] as String,
      organizationId: jsonMap['organization_id'] as String,
      batchId: jsonMap['batch_id'] as String,
      batchName: batchName,
      title: jsonMap['title'] as String,
      description: jsonMap['description'] as String?,
      durationMinutes: jsonMap['duration_minutes'] as int? ?? 10,
      questions: questionsList,
      createdBy: jsonMap['created_by'] as String,
      createdAt: jsonMap['created_at'] != null ? DateTime.parse(jsonMap['created_at'] as String) : null,
      updatedAt: jsonMap['updated_at'] != null ? DateTime.parse(jsonMap['updated_at'] as String) : null,
    );
  }

  @override
  Future<Quiz> updateQuiz(Quiz quiz) async {
    final payload = {
      'batch_id': quiz.batchId,
      'title': quiz.title,
      'description': quiz.description,
      'duration_minutes': quiz.durationMinutes,
      'questions': quiz.questions.map((q) => q.toJson()).toList(),
    };
    
    final response = await _client.from('quizzes').update(payload).eq('id', quiz.id).select('*, batches:batch_id(name)').single();
    
    final jsonMap = response;
    final batchData = jsonMap['batches'] as Map<String, dynamic>?;
    final batchName = batchData != null ? (batchData['name'] as String? ?? '') : '';
    
    final questionsList = (jsonMap['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
        
    return Quiz(
      id: jsonMap['id'] as String,
      organizationId: jsonMap['organization_id'] as String,
      batchId: jsonMap['batch_id'] as String,
      batchName: batchName,
      title: jsonMap['title'] as String,
      description: jsonMap['description'] as String?,
      durationMinutes: jsonMap['duration_minutes'] as int? ?? 10,
      questions: questionsList,
      createdBy: jsonMap['created_by'] as String,
      createdAt: jsonMap['created_at'] != null ? DateTime.parse(jsonMap['created_at'] as String) : null,
      updatedAt: jsonMap['updated_at'] != null ? DateTime.parse(jsonMap['updated_at'] as String) : null,
    );
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    await _client.from('quizzes').delete().eq('id', quizId);
  }

  @override
  Future<List<QuizAttempt>> getAttemptsForQuiz(String quizId) async {
    final response = await _client
        .from('quiz_attempts')
        .select('*, profiles:student_id(name)')
        .eq('quiz_id', quizId)
        .order('score', ascending: false);
        
    return (response as List).map((json) {
      final jsonMap = json as Map<String, dynamic>;
      final profileData = jsonMap['profiles'] as Map<String, dynamic>?;
      final studentName = profileData != null ? (profileData['name'] as String? ?? '') : '';
      
      return QuizAttempt(
        id: jsonMap['id'] as String,
        quizId: jsonMap['quiz_id'] as String,
        studentId: jsonMap['student_id'] as String,
        studentName: studentName,
        score: jsonMap['score'] as int? ?? 0,
        totalQuestions: jsonMap['total_questions'] as int? ?? 0,
        completedAt: DateTime.parse(jsonMap['completed_at'] as String),
      );
    }).toList();
  }

  @override
  Future<QuizAttempt> submitAttempt(String quizId, String studentId, int score, int totalQuestions) async {
    final payload = {
      'quiz_id': quizId,
      'student_id': studentId,
      'score': score,
      'total_questions': totalQuestions,
    };
    
    final response = await _client
        .from('quiz_attempts')
        .upsert(payload, onConflict: 'quiz_id,student_id')
        .select('*, profiles:student_id(name)')
        .single();
        
    final jsonMap = response;
    final profileData = jsonMap['profiles'] as Map<String, dynamic>?;
    final studentName = profileData != null ? (profileData['name'] as String? ?? '') : '';
    
    return QuizAttempt(
      id: jsonMap['id'] as String,
      quizId: jsonMap['quiz_id'] as String,
      studentId: jsonMap['student_id'] as String,
      studentName: studentName,
      score: jsonMap['score'] as int? ?? 0,
      totalQuestions: jsonMap['total_questions'] as int? ?? 0,
      completedAt: DateTime.parse(jsonMap['completed_at'] as String),
    );
  }
}
