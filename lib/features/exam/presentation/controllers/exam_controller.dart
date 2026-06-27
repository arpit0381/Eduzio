import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../data/repositories/exam_repository_impl.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ExamRepositoryImpl(client);
});

class ExamListController extends AsyncNotifier<List<Exam>> {
  @override
  Future<List<Exam>> build() async {
    return ref.read(examRepositoryProvider).getExams();
  }

  Future<void> addExam(Exam exam) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final created = await ref.read(examRepositoryProvider).createExam(exam);
      return [created, ...(state.value ?? [])];
    });
  }

  Future<void> editExam(Exam exam) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await ref.read(examRepositoryProvider).updateExam(exam);
      return (state.value ?? []).map((e) => e.id == exam.id ? updated : e).toList();
    });
  }

  Future<void> removeExam(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(examRepositoryProvider).deleteExam(id);
      return (state.value ?? []).where((e) => e.id != id).toList();
    });
  }
}

final examListProvider = AsyncNotifierProvider<ExamListController, List<Exam>>(() {
  return ExamListController();
});

/// Results for a specific exam
final examResultsProvider = FutureProvider.family<List<ExamResult>, String>((ref, examId) async {
  return ref.watch(examRepositoryProvider).getResultsForExam(examId);
});
