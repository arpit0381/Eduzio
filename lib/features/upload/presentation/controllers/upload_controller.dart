import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/isar_database.dart';
import '../../data/repositories/upload_repository_impl.dart';
import '../../domain/repositories/upload_repository.dart';
import 'cloudinary_service.dart';
import '../../data/models/isar_upload_task.dart';

// Provider for Connectivity
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

// Provider for CloudinaryService
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

// Provider for UploadRepository
final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  final cloudinary = ref.watch(cloudinaryServiceProvider);
  final isar = ref.watch(isarProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final connectivity = ref.watch(connectivityProvider);
  return UploadRepositoryImpl(cloudinary, isar, supabase, connectivity);
});

// Upload state definition
class UploadState {
  final double progress;
  final bool isUploading;
  final String? uploadedUrl;
  final String? errorMessage;
  final bool isOfflineQueued;

  const UploadState({
    this.progress = 0.0,
    this.isUploading = false,
    this.uploadedUrl,
    this.errorMessage,
    this.isOfflineQueued = false,
  });

  UploadState copyWith({
    double? progress,
    bool? isUploading,
    String? uploadedUrl,
    String? errorMessage,
    bool? isOfflineQueued,
  }) {
    return UploadState(
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      isOfflineQueued: isOfflineQueued ?? this.isOfflineQueued,
    );
  }
}

// Notifier for active uploads
class UploadController extends Notifier<UploadState> {
  late UploadRepository _repository;
  late Connectivity _connectivity;

  @override
  UploadState build() {
    _repository = ref.watch(uploadRepositoryProvider);
    _connectivity = ref.watch(connectivityProvider);
    _initConnectivityListener();
    return const UploadState();
  }

  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Device reconnected, sync queue
        _repository.syncOfflineQueue();
      }
    });
  }

  Future<void> uploadFile({
    required String filePath,
    required String fileName,
    required String folder,
    required String supabaseTable,
    required String supabaseColumn,
    required String entityId,
  }) async {
    state = const UploadState(isUploading: true, progress: 0.0);

    // Check connectivity first
    final connection = await _connectivity.checkConnectivity();
    if (connection.contains(ConnectivityResult.none)) {
      // Offline: Add to queue
      final task = IsarUploadTask()
        ..filePath = filePath
        ..fileName = fileName
        ..folder = folder
        ..entityType = folder.split('/').last
        ..queuedAt = DateTime.now()
        ..supabaseTable = supabaseTable
        ..supabaseColumn = supabaseColumn
        ..entityId = entityId;

      await _repository.queueOfflineUpload(task: task);
      state = const UploadState(
        isUploading: false,
        isOfflineQueued: true,
        errorMessage: 'Device is offline. Upload queued locally.',
      );
      return;
    }

    try {
      final url = await _repository.uploadFileDirectly(
        filePath: filePath,
        fileName: fileName,
        folder: folder,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = UploadState(
        isUploading: false,
        progress: 1.0,
        uploadedUrl: url,
      );
    } catch (e) {
      state = UploadState(
        isUploading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const UploadState();
  }
}

final uploadControllerProvider = NotifierProvider<UploadController, UploadState>(() {
  return UploadController();
});
