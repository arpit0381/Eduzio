import '../entities/note.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes(String organizationId, {String? batchId});
  Future<void> uploadNote(Note note);
  Future<void> deleteNote(String noteId);
}
