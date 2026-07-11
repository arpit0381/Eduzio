import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../controllers/notes_controller.dart';
import '../../domain/entities/note.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPDF(Note note) async {
    final url = note.fileUrl;
    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF file.')),
          );
        }
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading file to open...')),
      );
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final extension = note.fileName.toLowerCase().endsWith('.pdf') ? '' : '.pdf';
        final file = File('${dir.path}/${note.fileName}$extension');
        await file.writeAsBytes(response.bodyBytes);
        
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      } else {
        throw Exception('Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('Are you sure you want to delete "${note.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(notesControllerProvider.notifier).deleteNote(note.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesControllerProvider);
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final canManage = user != null && (user.role == UserProfileRole.admin || user.role == UserProfileRole.teacher);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Notes'),
        centerTitle: false,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/notes/upload'),
              icon: const Icon(LucideIcons.uploadCloud),
              label: const Text('Upload PDF'),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search notes by title or filename...',
              leading: const Icon(LucideIcons.search, size: 20),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(colors.surfaceContainerHighest.withValues(alpha: 0.3)),
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),

          // Notes List
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final filteredNotes = notes.where((note) {
                  return note.title.toLowerCase().contains(_searchQuery) ||
                      note.fileName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileText, size: 64, color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No study notes available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(notesControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _openPDF(note),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // File Icon indicator
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(LucideIcons.fileType2, color: colors.primary, size: 24),
                                ),
                                const SizedBox(width: 16),

                                // Note Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (note.description != null && note.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          note.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.calendar, size: 12, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(note.createdAt),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(LucideIcons.fileText, size: 12, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              note.fileName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Options
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.externalLink, size: 20),
                                      onPressed: () => _openPDF(note),
                                    ),
                                    if (canManage)
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                                        onPressed: () => _confirmDelete(note),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
