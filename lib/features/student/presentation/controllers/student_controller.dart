import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/student_detail.dart';
import '../../domain/repositories/student_repository.dart';
import '../../data/repositories/student_repository_impl.dart';

// Provider for StudentRepository
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StudentRepositoryImpl(client);
});

// AsyncNotifier for managing Students List State
class StudentsListController extends AsyncNotifier<List<StudentDetail>> {
  @override
  Future<List<StudentDetail>> build() async {
    return ref.read(studentRepositoryProvider).getStudents();
  }

  Future<void> addStudent(StudentDetail student, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newStudent = await ref.read(studentRepositoryProvider).createStudent(
            student: student,
            password: password,
          );
      final currentList = state.value ?? [];
      return [...currentList, newStudent];
    });
  }

  Future<void> editStudent(StudentDetail student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedStudent = await ref.read(studentRepositoryProvider).updateStudent(student);
      final currentList = state.value ?? [];
      return currentList.map((s) => s.profile.id == student.profile.id ? updatedStudent : s).toList();
    });
  }

  Future<void> deleteStudent(String studentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).deleteStudent(studentId);
      final currentList = state.value ?? [];
      return currentList.where((s) => s.profile.id != studentId).toList();
    });
  }

  Future<int> importStudents(String csvContent, String defaultPassword) async {
    state = const AsyncValue.loading();
    int count = 0;
    state = await AsyncValue.guard(() async {
      count = await ref.read(studentRepositoryProvider).importStudentsFromCsv(csvContent, defaultPassword);
      return ref.read(studentRepositoryProvider).getStudents();
    });
    return count;
  }
}

// Provider for Students List
final studentsListProvider = AsyncNotifierProvider<StudentsListController, List<StudentDetail>>(() {
  return StudentsListController();
});
