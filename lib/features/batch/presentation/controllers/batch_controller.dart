import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/batch_repository.dart';
import '../../data/repositories/batch_repository_impl.dart';

// Provider for BatchRepository
final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BatchRepositoryImpl(client);
});

// AsyncNotifier for managing Batches List State
class BatchesListController extends AsyncNotifier<List<Batch>> {
  @override
  Future<List<Batch>> build() async {
    return ref.read(batchRepositoryProvider).getBatches();
  }

  Future<void> addBatch(Batch batch) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newBatch = await ref.read(batchRepositoryProvider).createBatch(batch);
      final currentList = state.value ?? [];
      return [...currentList, newBatch];
    });
  }

  Future<void> editBatch(Batch batch) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedBatch = await ref.read(batchRepositoryProvider).updateBatch(batch);
      final currentList = state.value ?? [];
      return currentList.map((b) => b.id == batch.id ? updatedBatch : b).toList();
    });
  }

  Future<void> deleteBatch(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(batchRepositoryProvider).deleteBatch(id);
      final currentList = state.value ?? [];
      return currentList.where((b) => b.id != id).toList();
    });
  }
}

// Provider for Batches List
final batchesListProvider = AsyncNotifierProvider<BatchesListController, List<Batch>>(() {
  return BatchesListController();
});

// AsyncNotifier for managing Subjects List State
class SubjectsListController extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    return ref.read(batchRepositoryProvider).getSubjects();
  }

  Future<void> addSubject(Subject subject) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newSubject = await ref.read(batchRepositoryProvider).createSubject(subject);
      final currentList = state.value ?? [];
      return [...currentList, newSubject];
    });
  }

  Future<void> editSubject(Subject subject) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedSubject = await ref.read(batchRepositoryProvider).updateSubject(subject);
      final currentList = state.value ?? [];
      return currentList.map((s) => s.id == subject.id ? updatedSubject : s).toList();
    });
  }

  Future<void> deleteSubject(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(batchRepositoryProvider).deleteSubject(id);
      final currentList = state.value ?? [];
      return currentList.where((s) => s.id != id).toList();
    });
  }
}

// Provider for Subjects List
final subjectsListProvider = AsyncNotifierProvider<SubjectsListController, List<Subject>>(() {
  return SubjectsListController();
});
