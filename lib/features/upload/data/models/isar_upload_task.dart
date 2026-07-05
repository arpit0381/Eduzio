import 'package:isar/isar.dart';

part 'isar_upload_task.g.dart';

@collection
class IsarUploadTask {
  Id id = Isar.autoIncrement;
  
  late String filePath;
  late String fileName;
  late String folder;      // e.g. "eduzio/students/"
  late String entityType;  // e.g. "profile_photo", "receipt"
  late DateTime queuedAt;
  
  // Storage reference keys to update Supabase after uploading
  late String supabaseTable;
  late String supabaseColumn;
  late String entityId;
}
