import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/upload_controller.dart';

class UploadDialog extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;
  final String folder;
  final String supabaseTable;
  final String supabaseColumn;
  final String entityId;
  final double maxSizeBytes; // e.g. 5 * 1024 * 1024 (5MB)

  const UploadDialog({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.folder,
    required this.supabaseTable,
    required this.supabaseColumn,
    required this.entityId,
    this.maxSizeBytes = 5242880, // Default 5MB
  });

  @override
  ConsumerState<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<UploadDialog> {
  bool _isValidated = false;
  String? _validationError;
  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _validateFile();
  }

  Future<void> _validateFile() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _validationError = 'File does not exist on disk';
          _isValidated = true;
        });
        return;
      }

      final size = await file.length();
      _fileSizeBytes = size;

      if (size > widget.maxSizeBytes) {
        final maxMb = (widget.maxSizeBytes / (1024 * 1024)).toStringAsFixed(0);
        setState(() {
          _validationError = 'File size exceeds the maximum limit of ${maxMb}MB';
          _isValidated = true;
        });
        return;
      }

      // Check unsupported file extension (e.g. only PDFs and standard images)
      final ext = widget.fileName.split('.').last.toLowerCase();
      const allowed = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];
      if (!allowed.contains(ext)) {
        setState(() {
          _validationError = 'Unsupported file format. Please upload PDF or image';
          _isValidated = true;
        });
        return;
      }

      setState(() {
        _isValidated = true;
      });

      // Automatically trigger upload if validated
      _startUpload();
    } catch (e) {
      setState(() {
        _validationError = 'Failed to validate file: $e';
        _isValidated = true;
      });
    }
  }

  void _startUpload() {
    ref.read(uploadControllerProvider.notifier).uploadFile(
          filePath: widget.filePath,
          fileName: widget.fileName,
          folder: widget.folder,
          supabaseTable: widget.supabaseTable,
          supabaseColumn: widget.supabaseColumn,
          entityId: widget.entityId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadControllerProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final fileSizeKb = (_fileSizeBytes / 1024).toStringAsFixed(1);

    if (!_isValidated) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Validating file...'),
          ],
        ),
      );
    }

    if (_validationError != null) {
      return AlertDialog(
        title: const Text('Validation Failure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.alertTriangle, color: colors.error, size: 40),
            const SizedBox(height: 16),
            Text(_validationError!, style: TextStyle(color: colors.error)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ).animate().shake(duration: 400.ms);
    }

    return AlertDialog(
      title: Text(uploadState.isOfflineQueued
          ? 'Offline Queue'
          : (uploadState.uploadedUrl != null ? 'Success' : 'Uploading File')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (uploadState.isUploading) ...[
              // Uploading Progress State
              Text(
                widget.fileName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Size: ${fileSizeKb}KB',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      value: uploadState.progress,
                      strokeWidth: 8,
                      backgroundColor: colors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  Text(
                    '${(uploadState.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Please wait while we upload to cloud storage...'),
            ] else if (uploadState.isOfflineQueued) ...[
              // Offline Queued State
              const Icon(LucideIcons.wifiOff, color: Colors.orange, size: 48)
                  .animate()
                  .scale(duration: 300.ms),
              const SizedBox(height: 16),
              const Text(
                'You are currently offline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your file upload is queued locally. It will complete automatically when your internet connection is restored.',
                textAlign: TextAlign.center,
              ),
            ] else if (uploadState.uploadedUrl != null) ...[
              // Success State
              const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 56)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              const Text(
                'Upload Complete',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text('File uploaded and references successfully updated!'),
            ] else if (uploadState.errorMessage != null) ...[
              // Failure State
              Icon(LucideIcons.xCircle, color: colors.error, size: 56)
                  .animate()
                  .scale(duration: 300.ms),
              const SizedBox(height: 16),
              const Text(
                'Upload Failed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                uploadState.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (uploadState.isUploading)
          TextButton(
            onPressed: () {
              ref.read(uploadControllerProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        if (uploadState.errorMessage != null && !uploadState.isOfflineQueued) ...[
          TextButton(
            onPressed: () {
              ref.read(uploadControllerProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: _startUpload,
            child: const Text('Retry'),
          ),
        ],
        if (uploadState.isOfflineQueued || uploadState.uploadedUrl != null)
          FilledButton(
            onPressed: () {
              ref.read(uploadControllerProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
      ],
    );
  }
}
