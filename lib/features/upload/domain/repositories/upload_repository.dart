import '../../data/models/isar_upload_task.dart';

abstract class UploadRepository {
  Future<String> uploadFileDirectly({
    required String filePath,
    required String fileName,
    required String folder,
    required void Function(double progress) onProgress,
  });

  Future<void> queueOfflineUpload({required IsarUploadTask task});

  Future<List<IsarUploadTask>> getQueue();

  Future<void> deleteQueueTask(int id);

  Future<void> syncOfflineQueue();

  Future<void> deleteEntityFile({
    required String fileUrl,
    required String supabaseTable,
    required String supabaseColumn,
    required String entityId,
  });
}
