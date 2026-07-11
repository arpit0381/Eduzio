import '../entities/exam.dart';

abstract class ExamRepository {
  Future<List<Quiz>> getQuizzes(String organizationId, {String? batchId});
  Future<Quiz> createQuiz(Quiz quiz);
  Future<Quiz> updateQuiz(Quiz quiz);
  Future<void> deleteQuiz(String quizId);
  Future<List<QuizAttempt>> getAttemptsForQuiz(String quizId);
  Future<QuizAttempt> submitAttempt(String quizId, String studentId, int score, int totalQuestions);
}
