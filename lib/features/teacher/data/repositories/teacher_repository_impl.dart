import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../../../auth/domain/entities/user_profile.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final SupabaseClient _client;

  TeacherRepositoryImpl(this._client);

  @override
  Future<List<UserProfile>> getTeachers() async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('role', 'teacher')
        .isFilter('deleted_at', null);

    return (response as List).map((json) {
      return UserProfile(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String?,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: UserProfileRole.teacher,
      );
    }).toList();
  }

  @override
  Future<UserProfile> createTeacher({
    required UserProfile teacher,
    required String password,
  }) async {
    // Invoke the PostgreSQL RPC to create teacher securely
    final teacherId = await _client.rpc('create_new_teacher', params: {
      'teacher_email': teacher.email,
      'teacher_password': password,
      'teacher_name': teacher.name,
      'teacher_phone': teacher.phone,
    }) as String;

    return teacher.copyWith(id: teacherId);
  }

  @override
  Future<UserProfile> updateTeacher(UserProfile teacher) async {
    await _client.from('profiles').update({
      'name': teacher.name,
      'phone': teacher.phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', teacher.id);

    return teacher;
  }

  @override
  Future<void> deleteTeacher(String teacherId) async {
    await _client.from('profiles').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', teacherId);
  }
}
