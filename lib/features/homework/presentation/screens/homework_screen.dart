import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/homework.dart';
import '../controllers/homework_controller.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';


class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(homeworkListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework & Assignments'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Homework'),
      ),
      body: homeworkAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load homework', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(homeworkListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (homeworkList) {
          if (homeworkList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text('No assignments yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first homework assignment using the button below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              return _HomeworkCard(
                homework: homeworkList[index],
                onDelete: () => _confirmDelete(context, ref, homeworkList[index]),
                onEdit: () => _showEditDialog(context, ref, homeworkList[index]),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Homework hw) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: Text('Are you sure you want to delete "${hw.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(homeworkListProvider.notifier).removeHomework(hw.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _HomeworkFormDialog(
        onSave: (hw) => ref.read(homeworkListProvider.notifier).addHomework(hw),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Homework hw) {
    showDialog(
      context: context,
      builder: (ctx) => _HomeworkFormDialog(
        initialHomework: hw,
        onSave: (updated) => ref.read(homeworkListProvider.notifier).editHomework(updated),
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _HomeworkCard({
    required this.homework,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = homework.dueDate.isBefore(DateTime.now());
    final dueDateColor = isOverdue ? Colors.red : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Subject / Type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Assignment',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(homework.dueDate)}',
                  style: TextStyle(
                    color: dueDateColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              homework.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (homework.description != null && homework.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                homework.description!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (homework.fileUrl != null)
                  Chip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: const Text('File attached', style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkFormDialog extends ConsumerStatefulWidget {
  final Homework? initialHomework;
  final Future<void> Function(Homework) onSave;

  const _HomeworkFormDialog({this.initialHomework, required this.onSave});

  @override
  ConsumerState<_HomeworkFormDialog> createState() => _HomeworkFormDialogState();
}

class _HomeworkFormDialogState extends ConsumerState<_HomeworkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedBatchId;
  String? _selectedSubjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final hw = widget.initialHomework;
    _titleCtrl = TextEditingController(text: hw?.title ?? '');
    _descCtrl = TextEditingController(text: hw?.description ?? '');
    _dueDate = hw?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedBatchId = hw?.batchId;
    _selectedSubjectId = hw?.subjectId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesListProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);
    final isEdit = widget.initialHomework != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Assignment' : 'New Assignment'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description / Instructions',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Batch dropdown
                batchesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (batches) => DropdownButtonFormField<String>(
                    initialValue: _selectedBatchId,
                    decoration: const InputDecoration(
                      labelText: 'Batch *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: batches.map((b) => DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.name} (${b.code})'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedBatchId = v),
                    validator: (v) => v == null ? 'Please select a batch' : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Subject dropdown
                subjectsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (subjects) => DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('None')),
                      ...subjects.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                  ),
                ),
                const SizedBox(height: 16),
                // Due date picker
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    minimumSize: const Size(double.infinity, 56),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Due Date: ${DateFormat('dd MMM yyyy').format(_dueDate)}'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final hw = Homework(
      id: widget.initialHomework?.id ?? '',
      organizationId: widget.initialHomework?.organizationId ?? '',
      batchId: _selectedBatchId!,
      subjectId: _selectedSubjectId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      dueDate: _dueDate,
      fileUrl: widget.initialHomework?.fileUrl,
      createdBy: widget.initialHomework?.createdBy ?? '',
    );

    try {
      await widget.onSave(hw);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}
