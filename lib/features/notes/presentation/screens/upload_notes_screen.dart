import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';
import '../controllers/notes_controller.dart';

enum UploadMode { file, link }

class UploadNotesScreen extends ConsumerStatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  ConsumerState<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends ConsumerState<UploadNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  UploadMode _mode = UploadMode.file;
  String? _selectedBatchId;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to pick file: $e';
      });
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mode == UploadMode.file && _selectedFile == null) {
      setState(() {
        _uploadError = 'Please select a document file to upload.';
      });
      return;
    }

    if (_mode == UploadMode.link && _linkCtrl.text.trim().isEmpty) {
      setState(() {
        _uploadError = 'Please enter a valid Google Drive or Document URL.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      await ref.read(notesControllerProvider.notifier).uploadNote(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            batchId: _selectedBatchId,
            file: _mode == UploadMode.file ? _selectedFile : null,
            linkUrl: _mode == UploadMode.link ? _linkCtrl.text.trim() : null,
            fileName: _mode == UploadMode.file ? _selectedFile?.name : 'Google Drive Note',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note published successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString().replaceAll('Exception: ', '');
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesListProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Note'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: colors.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, color: colors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Publish notes by uploading local files to Supabase Storage OR pasting Google Drive / Web links for instant student viewing.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Segmented Toggle for File Upload vs Google Drive Link
              SegmentedButton<UploadMode>(
                segments: const [
                  ButtonSegment<UploadMode>(
                    value: UploadMode.file,
                    label: Text('File Upload'),
                    icon: Icon(LucideIcons.uploadCloud),
                  ),
                  ButtonSegment<UploadMode>(
                    value: UploadMode.link,
                    label: Text('Google Drive / Link'),
                    icon: Icon(LucideIcons.link),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (Set<UploadMode> newSelection) {
                  setState(() {
                    _mode = newSelection.first;
                    _uploadError = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Title input
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note Title',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description input
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(LucideIcons.alignLeft),
                ),
              ),
              const SizedBox(height: 16),

              // Batch Selection Dropdown
              batchesAsync.when(
                data: (batches) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedBatchId,
                    decoration: const InputDecoration(
                      labelText: 'Target Batch (Optional)',
                      prefixIcon: Icon(LucideIcons.users),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Batches (Global)'),
                      ),
                      ...batches.map((batch) {
                        return DropdownMenuItem<String?>(
                          value: batch.id,
                          child: Text(batch.name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedBatchId = val;
                      });
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading batches: $err'),
              ),
              const SizedBox(height: 24),

              // Mode 1: File Picker Container
              if (_mode == UploadMode.file) ...[
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedFile != null ? colors.primary : colors.outline.withValues(alpha: 0.2),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _selectedFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.fileType2, color: colors.onSurfaceVariant.withValues(alpha: 0.6), size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to select PDF, DOC, or image file',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Icon(LucideIcons.fileCheck, color: colors.primary, size: 32),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.x, color: Colors.red),
                                  onPressed: _clearFile,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],

              // Mode 2: Google Drive / Link Input Field
              if (_mode == UploadMode.link) ...[
                TextFormField(
                  controller: _linkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Google Drive or Web Document URL',
                    hintText: 'https://drive.google.com/file/d/.../view',
                    prefixIcon: Icon(LucideIcons.externalLink),
                    helperText: 'Paste Google Drive view link or any public PDF URL',
                  ),
                  validator: (val) {
                    if (_mode == UploadMode.link && (val == null || val.trim().isEmpty)) {
                      return 'Document link is required';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              if (_uploadError != null) ...[
                Text(
                  _uploadError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Upload Button
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _handleUpload,
                      icon: const Icon(LucideIcons.upload),
                      label: Text(_mode == UploadMode.file ? 'Publish File Note' : 'Publish Link Note'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
