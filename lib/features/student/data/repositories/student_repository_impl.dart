import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/student_detail.dart';
import '../../domain/entities/student_guardian.dart';
import '../../domain/repositories/student_repository.dart';
import '../../../auth/domain/entities/user_profile.dart';

class StudentRepositoryImpl implements StudentRepository {
  final SupabaseClient _client;

  StudentRepositoryImpl(this._client);

  @override
  Future<List<StudentDetail>> getStudents() async {
    final response = await _client
        .from('profiles')
        .select('*, student_guardians(*)')
        .eq('role', 'student')
        .isFilter('deleted_at', null);

    return (response as List).map((json) {
      final profile = UserProfile(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String?,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: UserProfileRole.student,
      );

      final guardianList = json['student_guardians'] as List?;
      final guardianJson = guardianList != null && guardianList.isNotEmpty
          ? guardianList.first as Map<String, dynamic>
          : null;

      final guardian = guardianJson != null
          ? StudentGuardian(
              studentId: guardianJson['student_id'] as String,
              guardianName: guardianJson['guardian_name'] as String,
              guardianPhone: guardianJson['guardian_phone'] as String?,
              guardianEmail: guardianJson['guardian_email'] as String?,
              relation: guardianJson['relation'] as String?,
            )
          : null;

      return StudentDetail(profile: profile, guardian: guardian);
    }).toList();
  }

  @override
  Future<StudentDetail> createStudent({
    required StudentDetail student,
    required String password,
  }) async {
    // Invoke the PostgreSQL RPC to create student securely
    final studentId = await _client.rpc('create_new_student', params: {
      'student_email': student.profile.email,
      'student_password': password,
      'student_name': student.profile.name,
      'student_phone': student.profile.phone,
      'guardian_name': student.guardian?.guardianName,
      'guardian_phone': student.guardian?.guardianPhone,
      'guardian_relation': student.guardian?.relation,
    }) as String;

    // Return the created student details
    final profile = student.profile.copyWith(id: studentId);
    final guardian = student.guardian?.copyWith(studentId: studentId);
    return StudentDetail(profile: profile, guardian: guardian);
  }

  @override
  Future<StudentDetail> updateStudent(StudentDetail student) async {
    // 1. Update Profile (name, phone)
    await _client.from('profiles').update({
      'name': student.profile.name,
      'phone': student.profile.phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', student.profile.id);

    // 2. Update Guardian Details if exists
    if (student.guardian != null) {
      await _client.from('student_guardians').upsert({
        'student_id': student.profile.id,
        'guardian_name': student.guardian!.guardianName,
        'guardian_phone': student.guardian!.guardianPhone,
        'relation': student.guardian!.relation,
      });
    }

    return student;
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    await _client.from('profiles').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', studentId);
  }
}
