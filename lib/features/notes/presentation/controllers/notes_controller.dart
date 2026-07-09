import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../upload/presentation/controllers/cloudinary_service.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../../../core/network/supabase_client.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotesRepositoryImpl(client);
});

class NotesController extends AsyncNotifier<List<Note>> {
  late final NotesRepository _repository;

  @override
  Future<List<Note>> build() async {
    _repository = ref.watch(notesRepositoryProvider);
    return _fetchNotes();
  }

  Future<List<Note>> _fetchNotes() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.organizationId == null) return [];

    if (user.role == UserProfileRole.student) {
      // 1. Fetch student's enrolled batches
      final client = ref.read(supabaseClientProvider);
      final response = await client
          .from('batch_students')
          .select('batch_id')
          .eq('student_id', user.id);
      
      final batchIds = (response as List).map((row) => row['batch_id'] as String).toList();
      
      // 2. Fetch notes and filter for this student
      final allNotes = await _repository.getNotes(user.organizationId!);
      return allNotes.where((note) => note.batchId == null || batchIds.contains(note.batchId)).toList();
    } else {
      // Admin / Teacher: can see all notes in the organization
      return _repository.getNotes(user.organizationId!);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotes());
  }

  Future<void> uploadNote({
    required String title,
    String? description,
    String? batchId,
    required PlatformFile file,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.organizationId == null) {
      throw Exception('User authentication context not found');
    }

    state = const AsyncValue.loading();

    try {
      // 1. Upload file to Cloudinary
      final cloudinary = CloudinaryService();
      final String cloudinaryUrl;

      if (file.bytes != null) {
        // Web / memory bytes
        cloudinaryUrl = await cloudinary.uploadFileBytes(
          bytes: file.bytes!,
          fileName: file.name,
          folder: 'notes',
          onProgress: (_) {},
        );
      } else if (file.path != null) {
        // Native path
        cloudinaryUrl = await cloudinary.uploadFile(
          filePath: file.path!,
          fileName: file.name,
          folder: 'notes',
          onProgress: (_) {},
        );
      } else {
        throw Exception('Selected file has no valid path or bytes');
      }

      // 2. Create note entity
      final note = Note(
        id: '',
        organizationId: user.organizationId!,
        batchId: batchId,
        title: title,
        description: description,
        fileUrl: cloudinaryUrl,
        fileName: file.name,
        uploadedBy: user.id,
        createdAt: DateTime.now(),
      );

      // 3. Save note to Supabase
      await _repository.uploadNote(note);

      // 4. Reload notes list
      state = await AsyncValue.guard(() => _fetchNotes());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteNote(noteId);
      state = await AsyncValue.guard(() => _fetchNotes());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final notesControllerProvider = AsyncNotifierProvider<NotesController, List<Note>>(() {
  return NotesController();
});
