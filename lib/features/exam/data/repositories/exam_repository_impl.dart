import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exam_repository.dart';

class ExamRepositoryImpl implements ExamRepository {
  final SupabaseClient _client;

  ExamRepositoryImpl(this._client);

  String _getOrgId() {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final orgId = user.userMetadata?['organization_id'] as String?;
    if (orgId == null) throw Exception('User not associated with any organization');
    return orgId;
  }

  Exam _mapExamJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      batchId: json['batch_id'] as String,
      subjectId: json['subject_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      examDate: DateTime.parse(json['exam_date'] as String),
      maxMarks: json['max_marks'] as int,
      passingMarks: json['passing_marks'] as int?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  ExamResult _mapResultJson(Map<String, dynamic> json) {
    return ExamResult(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      studentId: json['student_id'] as String,
      marksObtained: json['marks_obtained'] as int,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  @override
  Future<List<Exam>> getExams() async {
    final orgId = _getOrgId();
    final response = await _client
        .from('exams')
        .select()
        .eq('organization_id', orgId)
        .order('exam_date', ascending: false);
    return (response as List).map((json) => _mapExamJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Exam> createExam(Exam exam) async {
    final orgId = _getOrgId();
    final userId = _client.auth.currentUser!.id;

    final payload = {
      'organization_id': orgId,
      'batch_id': exam.batchId,
      'subject_id': exam.subjectId,
      'title': exam.title,
      'description': exam.description,
      'exam_date': exam.examDate.toIso8601String().substring(0, 10),
      'max_marks': exam.maxMarks,
      'passing_marks': exam.passingMarks,
      'created_by': userId,
    };

    final response = await _client.from('exams').insert(payload).select().single();
    return _mapExamJson(response);
  }

  @override
  Future<Exam> updateExam(Exam exam) async {
    final payload = {
      'batch_id': exam.batchId,
      'subject_id': exam.subjectId,
      'title': exam.title,
      'description': exam.description,
      'exam_date': exam.examDate.toIso8601String().substring(0, 10),
      'max_marks': exam.maxMarks,
      'passing_marks': exam.passingMarks,
    };

    final response = await _client
        .from('exams')
        .update(payload)
        .eq('id', exam.id)
        .select()
        .single();
    return _mapExamJson(response);
  }

  @override
  Future<void> deleteExam(String examId) async {
    await _client.from('exams').delete().eq('id', examId);
  }

  @override
  Future<List<ExamResult>> getResultsForExam(String examId) async {
    final response = await _client
        .from('exam_results')
        .select()
        .eq('exam_id', examId)
        .order('marks_obtained', ascending: false);
    return (response as List).map((json) => _mapResultJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveResults(String examId, List<ExamResult> results) async {
    final payload = results.map((r) => {
      'exam_id': examId,
      'student_id': r.studentId,
      'marks_obtained': r.marksObtained,
      'remarks': r.remarks,
    }).toList();

    await _client
        .from('exam_results')
        .upsert(payload, onConflict: 'exam_id,student_id');
  }
}
