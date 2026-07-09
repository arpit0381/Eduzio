import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/upload_repository.dart';
import '../../presentation/controllers/cloudinary_service.dart';
import '../models/isar_upload_task.dart';

class UploadRepositoryImpl implements UploadRepository {
  final CloudinaryService _cloudinary;
  final Isar? _isar;
  final SupabaseClient _supabase;
  final Connectivity _connectivity;

  UploadRepositoryImpl(
    this._cloudinary,
    this._isar,
    this._supabase,
    this._connectivity,
  );

  @override
  Future<String> uploadFileDirectly({
    required String filePath,
    required String fileName,
    required String folder,
    required void Function(double progress) onProgress,
  }) async {
    return _cloudinary.uploadFile(
      filePath: filePath,
      fileName: fileName,
      folder: folder,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> queueOfflineUpload({required IsarUploadTask task}) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.collection<IsarUploadTask>().put(task);
    });
  }

  @override
  Future<List<IsarUploadTask>> getQueue() async {
    if (_isar == null) return [];
    final list = await _isar.collection<IsarUploadTask>().where().findAll();
    list.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return list;
  }

  @override
  Future<void> deleteQueueTask(int id) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.collection<IsarUploadTask>().delete(id);
    });
  }

  @override
  Future<void> syncOfflineQueue() async {
    if (_isar == null) return;
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) return;

    final queue = await getQueue();
    if (queue.isEmpty) return;

    for (final task in queue) {
      try {
        final file = File(task.filePath);
        if (!await file.exists()) {
          // File deleted or lost, remove task from queue
          await deleteQueueTask(task.id);
          continue;
        }

        // Upload to Cloudinary
        final secureUrl = await _cloudinary.uploadFile(
          filePath: task.filePath,
          fileName: task.fileName,
          folder: task.folder,
          onProgress: (_) {},
        );

        // Update Supabase with secure URL
        await _supabase
            .from(task.supabaseTable)
            .update({task.supabaseColumn: secureUrl})
            .eq('id', task.entityId);

        // Remove from Isar queue
        await deleteQueueTask(task.id);
      } catch (e) {
        // Log and retry on next sync interval
        continue;
      }
    }
  }

  @override
  Future<void> deleteEntityFile({
    required String fileUrl,
    required String supabaseTable,
    required String supabaseColumn,
    required String entityId,
  }) async {
    // 1. Delete from Cloudinary
    await _cloudinary.deleteFile(fileUrl);

    // 2. Set field to null in Supabase
    await _supabase
        .from(supabaseTable)
        .update({supabaseColumn: null})
        .eq('id', entityId);
  }
}
