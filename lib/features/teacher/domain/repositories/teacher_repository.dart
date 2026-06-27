import '../../../auth/domain/entities/user_profile.dart';

abstract class TeacherRepository {
  /// Fetch all active teachers in the organization
  Future<List<UserProfile>> getTeachers();

  /// Create a new teacher user (registers auth user, creates profile row)
  Future<UserProfile> createTeacher({
    required UserProfile teacher,
    required String password,
  });

  /// Update teacher profile details
  Future<UserProfile> updateTeacher(UserProfile teacher);

  /// Delete teacher (soft delete)
  Future<void> deleteTeacher(String teacherId);
}
