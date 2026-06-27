import '../entities/homework.dart';

abstract class HomeworkRepository {
  /// Fetch all homework for the organization
  Future<List<Homework>> getHomework();

  /// Fetch homework for a specific batch
  Future<List<Homework>> getHomeworkForBatch(String batchId);

  /// Create a new homework assignment
  Future<Homework> createHomework(Homework homework);

  /// Update an existing homework assignment
  Future<Homework> updateHomework(Homework homework);

  /// Delete a homework assignment
  Future<void> deleteHomework(String homeworkId);
}
