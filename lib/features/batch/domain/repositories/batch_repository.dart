import '../entities/batch.dart';
import '../entities/subject.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class BatchRepository {
  // Batch CRUD
  Future<List<Batch>> getBatches();
  Future<Batch> createBatch(Batch batch);
  Future<Batch> updateBatch(Batch batch);
  Future<void> deleteBatch(String id);

  // Subject CRUD
  Future<List<Subject>> getSubjects();
  Future<Subject> createSubject(Subject subject);
  Future<Subject> updateSubject(Subject subject);
  Future<void> deleteSubject(String id);

  // Batch-Subject-Teacher Assignments
  Future<void> assignSubjectToBatch({
    required String batchId,
    required String subjectId,
    String? teacherId,
  });
  Future<List<Map<String, dynamic>>> getBatchSubjects(String batchId);

  // Student Enrollments
  Future<void> enrollStudentInBatch({
    required String batchId,
    required String studentId,
  });
  Future<void> removeStudentFromBatch({
    required String batchId,
    required String studentId,
  });
  Future<List<UserProfile>> getBatchStudents(String batchId);
}
