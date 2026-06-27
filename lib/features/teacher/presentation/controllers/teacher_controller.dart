import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../../data/repositories/teacher_repository_impl.dart';
import '../../../auth/domain/entities/user_profile.dart';

// Provider for TeacherRepository
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TeacherRepositoryImpl(client);
});

// AsyncNotifier for managing Teachers List State
class TeachersListController extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() async {
    return ref.read(teacherRepositoryProvider).getTeachers();
  }

  Future<void> addTeacher(UserProfile teacher, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newTeacher = await ref.read(teacherRepositoryProvider).createTeacher(
            teacher: teacher,
            password: password,
          );
      final currentList = state.value ?? [];
      return [...currentList, newTeacher];
    });
  }

  Future<void> editTeacher(UserProfile teacher) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedTeacher = await ref.read(teacherRepositoryProvider).updateTeacher(teacher);
      final currentList = state.value ?? [];
      return currentList.map((t) => t.id == teacher.id ? updatedTeacher : t).toList();
    });
  }

  Future<void> deleteTeacher(String teacherId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(teacherRepositoryProvider).deleteTeacher(teacherId);
      final currentList = state.value ?? [];
      return currentList.where((t) => t.id != teacherId).toList();
    });
  }
}

// Provider for Teachers List
final teachersListProvider = AsyncNotifierProvider<TeachersListController, List<UserProfile>>(() {
  return TeachersListController();
});

// FutureProvider to fetch batch and subject allocations for a specific teacher
final teacherAllocationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, teacherId) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('batch_subjects')
      .select('*, batch:batches(*), subject:subjects(*)')
      .eq('teacher_id', teacherId);
  return List<Map<String, dynamic>>.from(response);
});
