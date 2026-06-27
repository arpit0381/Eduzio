import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/homework.dart';
import '../../domain/repositories/homework_repository.dart';

class HomeworkRepositoryImpl implements HomeworkRepository {
  final SupabaseClient _client;

  HomeworkRepositoryImpl(this._client);

  String _getOrgId() {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final orgId = user.userMetadata?['organization_id'] as String?;
    if (orgId == null) throw Exception('User not associated with any organization');
    return orgId;
  }

  Homework _mapJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      batchId: json['batch_id'] as String,
      subjectId: json['subject_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      fileUrl: json['file_url'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  @override
  Future<List<Homework>> getHomework() async {
    final orgId = _getOrgId();
    final response = await _client
        .from('homework')
        .select()
        .eq('organization_id', orgId)
        .order('due_date', ascending: false);
    return (response as List).map((json) => _mapJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Homework>> getHomeworkForBatch(String batchId) async {
    final response = await _client
        .from('homework')
        .select()
        .eq('batch_id', batchId)
        .order('due_date', ascending: false);
    return (response as List).map((json) => _mapJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Homework> createHomework(Homework homework) async {
    final orgId = _getOrgId();
    final userId = _client.auth.currentUser!.id;

    final payload = {
      'organization_id': orgId,
      'batch_id': homework.batchId,
      'subject_id': homework.subjectId,
      'title': homework.title,
      'description': homework.description,
      'due_date': homework.dueDate.toIso8601String().substring(0, 10),
      'file_url': homework.fileUrl,
      'created_by': userId,
    };

    final response = await _client.from('homework').insert(payload).select().single();
    return _mapJson(response as Map<String, dynamic>);
  }

  @override
  Future<Homework> updateHomework(Homework homework) async {
    final payload = {
      'batch_id': homework.batchId,
      'subject_id': homework.subjectId,
      'title': homework.title,
      'description': homework.description,
      'due_date': homework.dueDate.toIso8601String().substring(0, 10),
      'file_url': homework.fileUrl,
    };

    final response = await _client
        .from('homework')
        .update(payload)
        .eq('id', homework.id)
        .select()
        .single();
    return _mapJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    await _client.from('homework').delete().eq('id', homeworkId);
  }
}
