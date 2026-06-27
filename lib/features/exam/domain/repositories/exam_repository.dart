import '../entities/exam.dart';

abstract class ExamRepository {
  Future<List<Exam>> getExams();
  Future<Exam> createExam(Exam exam);
  Future<Exam> updateExam(Exam exam);
  Future<void> deleteExam(String examId);
  Future<List<ExamResult>> getResultsForExam(String examId);
  Future<void> saveResults(String examId, List<ExamResult> results);
}
