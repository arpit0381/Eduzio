import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/exam.dart';
import '../controllers/exam_controller.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';
import '../../../student/presentation/controllers/student_controller.dart';

class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests & Exams'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Create Test'),
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load exams', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(examListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (exams) {
          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text('No tests scheduled', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first test using the button below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              return _ExamCard(
                exam: exams[index],
                onDelete: () => _confirmDelete(context, ref, exams[index]),
                onEdit: () => _showFormDialog(context, ref, exam: exams[index]),
                onEnterMarks: () => _showMarksBottomSheet(context, ref, exams[index]),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Exam exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Test?'),
        content: Text('Delete "${exam.title}"? All results will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(examListProvider.notifier).removeExam(exam.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, {Exam? exam}) {
    showDialog(
      context: context,
      builder: (ctx) => _ExamFormDialog(
        initialExam: exam,
        onSave: exam == null
            ? (e) => ref.read(examListProvider.notifier).addExam(e)
            : (e) => ref.read(examListProvider.notifier).editExam(e),
      ),
    );
  }

  void _showMarksBottomSheet(BuildContext context, WidgetRef ref, Exam exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _MarksEntrySheet(exam: exam),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onEnterMarks;

  const _ExamCard({
    required this.exam,
    required this.onDelete,
    required this.onEdit,
    required this.onEnterMarks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = exam.examDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Test',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPast ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isPast ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    isPast ? 'Completed' : 'Upcoming',
                    style: TextStyle(
                      color: isPast ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy').format(exam.examDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              exam.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (exam.description != null && exam.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                exam.description!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Max Marks: ${exam.maxMarks}${exam.passingMarks != null ? "  |  Pass: ${exam.passingMarks}" : ""}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPast)
                  OutlinedButton.icon(
                    onPressed: onEnterMarks,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Enter Marks'),
                  ),
                const SizedBox(width: 8),
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

class _ExamFormDialog extends ConsumerStatefulWidget {
  final Exam? initialExam;
  final Future<void> Function(Exam) onSave;

  const _ExamFormDialog({this.initialExam, required this.onSave});

  @override
  ConsumerState<_ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends ConsumerState<_ExamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _maxMarksCtrl;
  late final TextEditingController _passMarksCtrl;
  DateTime _examDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedBatchId;
  String? _selectedSubjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExam;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _maxMarksCtrl = TextEditingController(text: e?.maxMarks.toString() ?? '100');
    _passMarksCtrl = TextEditingController(text: e?.passingMarks?.toString() ?? '');
    _examDate = e?.examDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedBatchId = e?.batchId;
    _selectedSubjectId = e?.subjectId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxMarksCtrl.dispose();
    _passMarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesListProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);
    final isEdit = widget.initialExam != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Test' : 'Create Test'),
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
                    labelText: 'Test Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.quiz),
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
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
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
                      ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxMarksCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Marks *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _passMarksCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Passing Marks',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (int.tryParse(v.trim()) == null) return 'Must be a number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    minimumSize: const Size(double.infinity, 56),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _examDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _examDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Exam Date: ${DateFormat('dd MMM yyyy').format(_examDate)}'),
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
              : Text(isEdit ? 'Save Changes' : 'Create Test'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final exam = Exam(
      id: widget.initialExam?.id ?? '',
      organizationId: widget.initialExam?.organizationId ?? '',
      batchId: _selectedBatchId!,
      subjectId: _selectedSubjectId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      examDate: _examDate,
      maxMarks: int.parse(_maxMarksCtrl.text.trim()),
      passingMarks: _passMarksCtrl.text.trim().isEmpty ? null : int.parse(_passMarksCtrl.text.trim()),
      createdBy: widget.initialExam?.createdBy ?? '',
    );

    try {
      await widget.onSave(exam);
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

class _MarksEntrySheet extends ConsumerStatefulWidget {
  final Exam exam;

  const _MarksEntrySheet({required this.exam});

  @override
  ConsumerState<_MarksEntrySheet> createState() => _MarksEntrySheetState();
}

class _MarksEntrySheetState extends ConsumerState<_MarksEntrySheet> {
  final Map<String, TextEditingController> _marksControllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final ctrl in _marksControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);
    final existingResultsAsync = ref.watch(examResultsProvider(widget.exam.id));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Marks — ${widget.exam.title}',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Max Marks: ${widget.exam.maxMarks}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _saveMarks(context),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: studentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (students) {
                  return existingResultsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error loading results: $e')),
                    data: (existingResults) {
                      // Pre-fill marks controllers with existing values
                      for (final student in students) {
                        if (!_marksControllers.containsKey(student.profile.id)) {
                          final existing = existingResults.where((r) => r.studentId == student.profile.id);
                          _marksControllers[student.profile.id] = TextEditingController(
                            text: existing.isNotEmpty ? existing.first.marksObtained.toString() : '',
                          );
                        }
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final ctrl = _marksControllers[student.profile.id]!;
                          final marksText = ctrl.text;
                          final marks = int.tryParse(marksText) ?? -1;
                          final isPassing = widget.exam.passingMarks != null && marks >= widget.exam.passingMarks!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Text(
                                    student.profile.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    student.profile.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintText: '—',
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      suffixText: '/${widget.exam.maxMarks}',
                                      filled: marks >= 0,
                                      fillColor: marks >= 0
                                          ? (isPassing ? Colors.green.shade50 : Colors.red.shade50)
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMarks(BuildContext context) async {
    setState(() => _isSaving = true);

    try {
      final results = _marksControllers.entries
          .where((e) => e.value.text.isNotEmpty)
          .map((e) => ExamResult(
                id: '',
                examId: widget.exam.id,
                studentId: e.key,
                marksObtained: int.parse(e.value.text),
              ))
          .toList();

      await ref.read(examRepositoryProvider).saveResults(widget.exam.id, results);
      // Invalidate cache
      ref.invalidate(examResultsProvider(widget.exam.id));

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks saved successfully!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving marks: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isSaving = false);
    }
  }
}
