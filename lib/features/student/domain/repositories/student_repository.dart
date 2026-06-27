import '../entities/student_detail.dart';

abstract class StudentRepository {
  /// Fetch all active students in the organization
  Future<List<StudentDetail>> getStudents();

  /// Create a new student (registers auth user, creates profile & guardian rows)
  Future<StudentDetail> createStudent({
    required StudentDetail student,
    required String password,
  });

  /// Update student profile and guardian details
  Future<StudentDetail> updateStudent(StudentDetail student);

  /// Delete student (soft delete)
  Future<void> deleteStudent(String studentId);

  /// Import students in bulk from a CSV string
  Future<int> importStudentsFromCsv(String csvContent, String defaultPassword);
}
