import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/upload_repository.dart';
import '../models/isar_upload_task.dart';

class UploadRepositoryImpl implements UploadRepository {
  final Isar? _isar;
  final SupabaseClient _supabase;
  final Connectivity _connectivity;

  UploadRepositoryImpl(
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
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at path: $filePath');
    }
    final bytes = await file.readAsBytes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$folder/$timestamp-$sanitizedName';

    await _supabase.storage.from('uploads').uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    onProgress(1.0);
    return _supabase.storage.from('uploads').getPublicUrl(storagePath);
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
          await deleteQueueTask(task.id);
          continue;
        }

        final secureUrl = await uploadFileDirectly(
          filePath: task.filePath,
          fileName: task.fileName,
          folder: task.folder,
          onProgress: (_) {},
        );

        await _supabase
            .from(task.supabaseTable)
            .update({task.supabaseColumn: secureUrl})
            .eq('id', task.entityId);

        await deleteQueueTask(task.id);
      } catch (e) {
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
    await _supabase
        .from(supabaseTable)
        .update({supabaseColumn: null})
        .eq('id', entityId);
  }
}
