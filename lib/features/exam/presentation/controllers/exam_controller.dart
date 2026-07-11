import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../data/repositories/exam_repository_impl.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ExamRepositoryImpl(client);
});

class QuizListController extends AsyncNotifier<List<Quiz>> {
  @override
  Future<List<Quiz>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null || user.organizationId == null) return [];

    final repo = ref.read(examRepositoryProvider);
    if (user.role == UserProfileRole.student) {
      final stats = ref.read(studentDashboardStatsProvider).value;
      if (stats == null || stats.enrolledBatches.isEmpty) return [];
      
      final List<Quiz> allQuizzes = [];
      for (final batch in stats.enrolledBatches) {
        final batchQuizzes = await repo.getQuizzes(user.organizationId!, batchId: batch.id);
        allQuizzes.addAll(batchQuizzes);
      }
      return allQuizzes;
    } else {
      return repo.getQuizzes(user.organizationId!);
    }
  }

  Future<void> addQuiz(Quiz quiz) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final created = await ref.read(examRepositoryProvider).createQuiz(quiz);
      return [created, ...(state.value ?? [])];
    });
  }

  Future<void> editQuiz(Quiz quiz) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await ref.read(examRepositoryProvider).updateQuiz(quiz);
      return (state.value ?? []).map((q) => q.id == quiz.id ? updated : q).toList();
    });
  }

  Future<void> removeQuiz(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(examRepositoryProvider).deleteQuiz(id);
      return (state.value ?? []).where((q) => q.id != id).toList();
    });
  }
}

final examListProvider = AsyncNotifierProvider<QuizListController, List<Quiz>>(() {
  return QuizListController();
});

final quizAttemptsProvider = FutureProvider.family<List<QuizAttempt>, String>((ref, quizId) async {
  return ref.watch(examRepositoryProvider).getAttemptsForQuiz(quizId);
});
