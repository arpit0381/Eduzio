import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/batch_repository.dart';
import '../../../auth/domain/entities/user_profile.dart';

class BatchRepositoryImpl implements BatchRepository {
  final SupabaseClient _client;

  BatchRepositoryImpl(this._client);

  String _getOrgId() {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final orgId = user.userMetadata?['organization_id'] as String?;
    if (orgId == null) throw Exception('User not associated with any organization');
    return orgId;
  }

  Batch _mapToBatch(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
    );
  }

  Subject _mapToSubject(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
    );
  }

  @override
  Future<List<Batch>> getBatches() async {
    final response = await _client
        .from('batches')
        .select()
        .isFilter('deleted_at', null);
    
    return (response as List).map((json) => _mapToBatch(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Batch> createBatch(Batch batch) async {
    final orgId = _getOrgId();
    final response = await _client.from('batches').insert({
      'organization_id': orgId,
      'name': batch.name,
      'code': batch.code,
      'description': batch.description,
      'start_date': batch.startDate?.toIso8601String(),
      'end_date': batch.endDate?.toIso8601String(),
    }).select().single();

    return _mapToBatch(response);
  }

  @override
  Future<Batch> updateBatch(Batch batch) async {
    final response = await _client.from('batches').update({
      'name': batch.name,
      'code': batch.code,
      'description': batch.description,
      'start_date': batch.startDate?.toIso8601String(),
      'end_date': batch.endDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', batch.id).select().single();

    return _mapToBatch(response);
  }

  @override
  Future<void> deleteBatch(String id) async {
    await _client.from('batches').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<List<Subject>> getSubjects() async {
    final response = await _client
        .from('subjects')
        .select()
        .isFilter('deleted_at', null);

    return (response as List).map((json) => _mapToSubject(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Subject> createSubject(Subject subject) async {
    final orgId = _getOrgId();
    final response = await _client.from('subjects').insert({
      'organization_id': orgId,
      'name': subject.name,
      'code': subject.code,
      'description': subject.description,
    }).select().single();

    return _mapToSubject(response);
  }

  @override
  Future<Subject> updateSubject(Subject subject) async {
    final response = await _client.from('subjects').update({
      'name': subject.name,
      'code': subject.code,
      'description': subject.description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', subject.id).select().single();

    return _mapToSubject(response);
  }

  @override
  Future<void> deleteSubject(String id) async {
    await _client.from('subjects').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> assignSubjectToBatch({
    required String batchId,
    required String subjectId,
    String? teacherId,
  }) async {
    await _client.from('batch_subjects').upsert({
      'batch_id': batchId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getBatchSubjects(String batchId) async {
    final response = await _client
        .from('batch_subjects')
        .select('*, subject:subjects(*), teacher:profiles(*)')
        .eq('batch_id', batchId);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> enrollStudentInBatch({
    required String batchId,
    required String studentId,
  }) async {
    await _client.from('batch_students').insert({
      'batch_id': batchId,
      'student_id': studentId,
    });
  }

  @override
  Future<void> removeStudentFromBatch({
    required String batchId,
    required String studentId,
  }) async {
    await _client.from('batch_students').delete().eq('batch_id', batchId).eq('student_id', studentId);
  }

  @override
  Future<List<UserProfile>> getBatchStudents(String batchId) async {
    final response = await _client
        .from('batch_students')
        .select('student:profiles(*)')
        .eq('batch_id', batchId);

    return (response as List).map((json) {
      final studentJson = json['student'] as Map<String, dynamic>;
      return UserProfile(
        id: studentJson['id'] as String,
        organizationId: studentJson['organization_id'] as String?,
        name: studentJson['name'] as String,
        email: studentJson['email'] as String,
        phone: studentJson['phone'] as String?,
        role: UserProfileRole.fromKey(studentJson['role'] as String),
      );
    }).toList();
  }
}
