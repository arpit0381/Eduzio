import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/homework.dart';
import '../../domain/repositories/homework_repository.dart';
import '../../data/repositories/homework_repository_impl.dart';

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HomeworkRepositoryImpl(client);
});

class HomeworkListController extends AsyncNotifier<List<Homework>> {
  @override
  Future<List<Homework>> build() async {
    return ref.read(homeworkRepositoryProvider).getHomework();
  }

  Future<void> addHomework(Homework homework) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final created = await ref.read(homeworkRepositoryProvider).createHomework(homework);
      final current = state.value ?? [];
      return [created, ...current];
    });
  }

  Future<void> editHomework(Homework homework) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await ref.read(homeworkRepositoryProvider).updateHomework(homework);
      final current = state.value ?? [];
      return current.map((h) => h.id == homework.id ? updated : h).toList();
    });
  }

  Future<void> removeHomework(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(homeworkRepositoryProvider).deleteHomework(id);
      final current = state.value ?? [];
      return current.where((h) => h.id != id).toList();
    });
  }
}

final homeworkListProvider = AsyncNotifierProvider<HomeworkListController, List<Homework>>(() {
  return HomeworkListController();
});
