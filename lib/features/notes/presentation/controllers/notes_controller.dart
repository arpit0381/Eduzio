import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../../../core/network/supabase_client.dart';
import 'package:flutter/foundation.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotesRepositoryImpl(client);
});

class NotesController extends AsyncNotifier<List<Note>> {
  late NotesRepository _repository;

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
    PlatformFile? file,
    String? linkUrl,
    String? fileName,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.organizationId == null) {
      throw Exception('User authentication context not found');
    }

    state = const AsyncValue.loading();

    try {
      final client = ref.read(supabaseClientProvider);
      String uploadedUrl = '';
      String resolvedFileName = fileName ?? file?.name ?? 'Document';

      if (linkUrl != null && linkUrl.trim().isNotEmpty) {
        uploadedUrl = linkUrl.trim();
        // Google Drive link auto-formatting
        if (uploadedUrl.contains('drive.google.com')) {
          final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
          final match = reg.firstMatch(uploadedUrl);
          if (match != null) {
            final driveId = match.group(1);
            uploadedUrl = 'https://drive.google.com/uc?export=download&id=$driveId';
          }
        }
      } else if (file != null) {
        final Uint8List fileBytes = file.bytes ?? 
            (file.path != null && file.path!.isNotEmpty ? await File(file.path!).readAsBytes() : Uint8List(0));

        if (fileBytes.isEmpty) {
          throw Exception('Selected file is empty or has no content');
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final sanitizedName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final storagePath = '${user.organizationId}/$timestamp-$sanitizedName';

        await client.storage.from('notes').uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

        uploadedUrl = client.storage.from('notes').getPublicUrl(storagePath);
      } else {
        throw Exception('Please provide either a PDF file or a document link.');
      }

      // Create note entity
      final note = Note(
        id: '',
        organizationId: user.organizationId!,
        batchId: batchId,
        title: title,
        description: description,
        fileUrl: uploadedUrl,
        fileName: resolvedFileName,
        uploadedBy: user.id,
        createdAt: DateTime.now(),
      );

      // Save note to Supabase
      await _repository.uploadNote(note);

      // 4. Send notification and insert announcement
      try {
        final client = ref.read(supabaseClientProvider);
        
        // Insert in-app announcement
        await client.from('announcements').insert({
          'organization_id': user.organizationId,
          'title': 'New Study Note: $title',
          'content': 'A new note has been uploaded: $title',
          'target_roles': ['student'],
          'batch_id': batchId,
          'created_by': user.id,
        });

        // Send Push Notification
        await client.functions.invoke(
          'send-fcm',
          body: {
            'title': 'New Study Note Uploaded',
            'body': 'A new note "$title" is available.',
            'target': batchId != null ? 'batch' : 'organization',
            'targetRole': 'student',
            'batchId': batchId,
            'organizationId': user.organizationId,
            'isGlobal': false,
          },
        );
      } catch (e) {
        debugPrint('Failed to send notification for note upload: $e');
      }

      // 5. Reload notes list
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
