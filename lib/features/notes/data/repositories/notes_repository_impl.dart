import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final SupabaseClient _client;

  NotesRepositoryImpl(this._client);

  @override
  Future<List<Note>> getNotes(String organizationId, {String? batchId}) async {
    // If student, filter by batch or global notes
    var query = _client.from('notes').select().eq('organization_id', organizationId);
    
    if (batchId != null) {
      // Show notes belonging specifically to the student's batch, or generic institute notes
      query = query.or('batch_id.eq.$batchId,batch_id.is.null');
    }
    
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Note.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> uploadNote(Note note) async {
    await _client.from('notes').insert(note.toJson());
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }
}
