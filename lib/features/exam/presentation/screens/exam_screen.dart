import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/exam.dart';
import '../controllers/exam_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';

class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(authStateProvider);
    final examsAsync = ref.watch(examListProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return userProfileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error loading user profile: $err'))),
      data: (profile) {
        if (profile == null) return const Scaffold(body: Center(child: Text('User not authenticated')));
        final isStudent = profile.role == UserProfileRole.student;

        return Scaffold(
          appBar: AppBar(
            title: Text(isStudent ? 'Available Quizzes' : 'Manage Quizzes'),
            centerTitle: false,
          ),
          floatingActionButton: !isStudent
              ? FloatingActionButton.extended(
                  onPressed: () => _showFormDialog(context, ref, profile),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Create Quiz'),
                )
              : null,
          body: examsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 48, color: colors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load quizzes: $err', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(examListProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (quizzes) {
              if (quizzes.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'public/undraw_questions_52ic.svg',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Quizzes Found',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isStudent
                              ? 'All caught up! Check back later for new quizzes.'
                              : 'Create your first quiz using the button below.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  return _QuizCard(
                    quiz: quiz,
                    profile: profile,
                    onDelete: () => _confirmDelete(context, ref, quiz),
                    onEdit: () => _showFormDialog(context, ref, profile, quiz: quiz),
                    onViewLeaderboard: () => _showLeaderboard(context, ref, quiz),
                    onTakeQuiz: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizPlayScreen(quiz: quiz, studentId: profile.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Quiz quiz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content: Text('Are you sure you want to delete "${quiz.title}"? All student attempts will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(examListProvider.notifier).removeQuiz(quiz.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, UserProfile profile, {Quiz? quiz}) {
    showDialog(
      context: context,
      builder: (ctx) => _QuizFormDialog(
        initialQuiz: quiz,
        profile: profile,
        onSave: quiz == null
            ? (q) => ref.read(examListProvider.notifier).addQuiz(q)
            : (q) => ref.read(examListProvider.notifier).editQuiz(q),
      ),
    );
  }

  void _showLeaderboard(BuildContext context, WidgetRef ref, Quiz quiz) {
    showDialog(
      context: context,
      builder: (ctx) => _LeaderboardDialog(quiz: quiz),
    );
  }
}

class _QuizCard extends ConsumerWidget {
  final Quiz quiz;
  final UserProfile profile;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onViewLeaderboard;
  final VoidCallback onTakeQuiz;

  const _QuizCard({
    required this.quiz,
    required this.profile,
    required this.onDelete,
    required this.onEdit,
    required this.onViewLeaderboard,
    required this.onTakeQuiz,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isStudent = profile.role == UserProfileRole.student;
    final attemptsAsync = ref.watch(quizAttemptsProvider(quiz.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quiz.batchName != null && quiz.batchName!.isNotEmpty ? quiz.batchName! : 'Batch-wise',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${quiz.durationMinutes} min',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${quiz.questions.length} Questions',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quiz.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (quiz.description != null && quiz.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                quiz.description!,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            attemptsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error: $err', style: TextStyle(color: colors.error)),
              data: (attempts) {
                // Find if this student completed the quiz
                final studentAttempt = attempts.where((a) => a.studentId == profile.id).firstOrNull;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isStudent) ...[
                      if (studentAttempt != null)
                        Row(
                          children: [
                            const Icon(LucideIcons.checkCircle, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Score: ${studentAttempt.score}/${studentAttempt.totalQuestions}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(LucideIcons.clock, color: Colors.orange, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Pending',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ElevatedButton(
                        onPressed: studentAttempt != null ? null : onTakeQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: studentAttempt != null ? colors.surfaceContainer : colors.primary,
                          foregroundColor: studentAttempt != null ? colors.onSurface : colors.onPrimary,
                        ),
                        child: Text(studentAttempt != null ? 'Completed' : 'Start Quiz'),
                      ),
                    ] else ...[
                      Text(
                        'Attempts: ${attempts.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: onViewLeaderboard,
                            icon: const Icon(LucideIcons.award, size: 16),
                            label: const Text('Scores', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(LucideIcons.edit, size: 18),
                            tooltip: 'Edit',
                            onPressed: onEdit,
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.trash2, color: colors.error, size: 18),
                            tooltip: 'Delete',
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ]
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizFormDialog extends ConsumerStatefulWidget {
  final Quiz? initialQuiz;
  final UserProfile profile;
  final Future<void> Function(Quiz) onSave;

  const _QuizFormDialog({this.initialQuiz, required this.profile, required this.onSave});

  @override
  ConsumerState<_QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends ConsumerState<_QuizFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _durationCtrl;
  String? _selectedBatchId;
  final List<QuizQuestion> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuiz;
    _titleCtrl = TextEditingController(text: q?.title ?? '');
    _descCtrl = TextEditingController(text: q?.description ?? '');
    _durationCtrl = TextEditingController(text: q?.durationMinutes.toString() ?? '10');
    _selectedBatchId = q?.batchId;
    if (q != null) {
      _questions.addAll(q.questions);
    } else {
      // Start with 1 default empty question
      _addEmptyQuestion();
    }
  }

  void _addEmptyQuestion() {
    setState(() {
      _questions.add(const QuizQuestion(
        questionText: '',
        options: ['', '', '', ''],
        correctOptionIndex: 0,
      ));
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quizzes must contain at least 1 question.')),
      );
      return;
    }
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final batchesAsync = ref.watch(batchesListProvider);
    final isEdit = widget.initialQuiz != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 640,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Quiz' : 'Create Quiz',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quiz Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description / Instructions',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: batchesAsync.when(
                              loading: () => const Center(child: LinearProgressIndicator()),
                              error: (e, _) => Text('Error: $e'),
                              data: (batches) => DropdownButtonFormField<String>(
                                initialValue: _selectedBatchId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Batch *',
                                  border: OutlineInputBorder(),
                                ),
                                items: batches.map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text('${b.name} (${b.code})'),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedBatchId = v),
                                validator: (v) => v == null ? 'Please select a batch' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration (Minutes) *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (int.tryParse(v.trim()) == null) return 'Must be a number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Questions (${_questions.length})',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                          TextButton.icon(
                            onPressed: _addEmptyQuestion,
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: const Text('Add Question'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        itemBuilder: (context, qIdx) {
                          final question = _questions[qIdx];
                          return Card(
                            color: colors.surfaceContainerLow,
                            margin: const EdgeInsets.only(bottom: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Question ${qIdx + 1}',
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: Icon(LucideIcons.trash2, color: colors.error, size: 18),
                                        onPressed: () => _removeQuestion(qIdx),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: question.questionText,
                                    decoration: const InputDecoration(
                                      labelText: 'Question Text *',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      _questions[qIdx] = _questions[qIdx].copyWith(questionText: v);
                                    },
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Question text is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Options & Correct Answer Selection:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Render 4 option boxes
                                  ...List.generate(4, (oIdx) {
                                    final optionLetters = ['A', 'B', 'C', 'D'];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _questions[qIdx] = _questions[qIdx].copyWith(correctOptionIndex: oIdx);
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Icon(
                                                _questions[qIdx].correctOptionIndex == oIdx
                                                    ? LucideIcons.checkCircle2
                                                    : LucideIcons.circle,
                                                color: _questions[qIdx].correctOptionIndex == oIdx
                                                    ? colors.primary
                                                    : colors.outline.withValues(alpha: 0.5),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: question.options[oIdx],
                                              decoration: InputDecoration(
                                                labelText: 'Option ${optionLetters[oIdx]} *',
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                border: const OutlineInputBorder(),
                                              ),
                                              onChanged: (v) {
                                                final list = List<String>.from(_questions[qIdx].options);
                                                list[oIdx] = v;
                                                _questions[qIdx] = _questions[qIdx].copyWith(options: list);
                                              },
                                              validator: (v) => v == null || v.trim().isEmpty ? 'Option is required' : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Save Quiz' : 'Create Quiz'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final quiz = Quiz(
      id: widget.initialQuiz?.id ?? '',
      organizationId: widget.initialQuiz?.organizationId ?? widget.profile.organizationId!,
      batchId: _selectedBatchId!,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      durationMinutes: int.parse(_durationCtrl.text.trim()),
      questions: _questions,
      createdBy: widget.initialQuiz?.createdBy ?? widget.profile.id,
    );

    try {
      await widget.onSave(quiz);
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

// Extension to copy fields in QuizQuestion helper
extension QuizQuestionCopy on QuizQuestion {
  QuizQuestion copyWith({
    String? questionText,
    List<String>? options,
    int? correctOptionIndex,
  }) {
    return QuizQuestion(
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    );
  }
}

class _LeaderboardDialog extends ConsumerWidget {
  final Quiz quiz;

  const _LeaderboardDialog({required this.quiz});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(quizAttemptsProvider(quiz.id));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quiz.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('Score Summary & Leaderboard', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
      content: SizedBox(
        width: 440,
        height: 380,
        child: attemptsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (attempts) {
            if (attempts.isEmpty) {
              return const Center(child: Text('No student attempts registered yet.'));
            }

            return ListView.separated(
              itemCount: attempts.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                final scorePercent = (attempt.score / attempt.totalQuestions * 100).toStringAsFixed(0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attempt.studentName ?? 'Student',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Completed at: ${DateFormat('dd MMM yyyy, hh:mm a').format(attempt.completedAt.toLocal())}',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${attempt.score}/${attempt.totalQuestions}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                          Text(
                            '$scorePercent%',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

// ── PLAY/STUDENT INTERACTIVE QUIZ PLAY SCREEN ───────────────────────────
class QuizPlayScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  final String studentId;

  const QuizPlayScreen({super.key, required this.quiz, required this.studentId});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {}; // questionIndex -> chosenOptionIndex
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isSubmitting = false;
  QuizAttempt? _resultAttempt;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.quiz.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _autoSubmit();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _autoSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time expired! Automatically submitting your answers...')),
    );
    _submitQuiz();
  }

  Future<void> _submitQuiz() async {
    if (_timer != null) _timer!.cancel();
    setState(() => _isSubmitting = true);

    // Calculate score
    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final correctIdx = widget.quiz.questions[i].correctOptionIndex;
      final userIdx = _userAnswers[i];
      if (userIdx != null && userIdx == correctIdx) {
        score++;
      }
    }

    try {
      final repo = ref.read(examRepositoryProvider);
      final attempt = await repo.submitAttempt(
        widget.quiz.id,
        widget.studentId,
        score,
        widget.quiz.questions.length,
      );

      // Invalidate providers
      ref.invalidate(examListProvider);
      ref.invalidate(quizAttemptsProvider(widget.quiz.id));

      setState(() {
        _resultAttempt = attempt;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Show result view if completed
    if (_resultAttempt != null) {
      return _buildResultView(_resultAttempt!);
    }

    if (_isSubmitting) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Submitting your quiz...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final question = widget.quiz.questions[_currentQuestionIndex];
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final timerColor = _secondsRemaining < 60 ? Colors.red : colors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(LucideIcons.timer, color: timerColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$minutes:$seconds',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      color: timerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '${((_currentQuestionIndex + 1) / widget.quiz.questions.length * 100).toStringAsFixed(0)}% Done',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 32),

              // Question Card
              Card(
                color: colors.primaryContainer.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    question.questionText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Choice Options List
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _userAnswers[_currentQuestionIndex] == index;
                    final optionLetter = ['A', 'B', 'C', 'D'][index];

                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        side: BorderSide(
                          color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        backgroundColor: isSelected ? colors.primary.withValues(alpha: 0.05) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _userAnswers[_currentQuestionIndex] = index;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary : colors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              optionLetter,
                              style: TextStyle(
                                color: isSelected ? colors.onPrimary : colors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              question.options[index],
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Navigation Bottom Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentQuestionIndex == 0
                        ? null
                        : () {
                            setState(() => _currentQuestionIndex--);
                          },
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (_currentQuestionIndex == widget.quiz.questions.length - 1)
                    FilledButton.icon(
                      onPressed: _submitQuiz,
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Submit Quiz'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _currentQuestionIndex++);
                      },
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      label: const Text('Next'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultView(QuizAttempt attempt) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final percent = (attempt.score / attempt.totalQuestions * 100).toInt();

    String titleMessage = 'Keep practicing!';
    String subtitleMessage = 'Review your course materials and try again.';
    Color progressColor = Colors.red;

    if (percent >= 80) {
      titleMessage = 'Spectacular! 🎉';
      subtitleMessage = 'You have mastered this quiz topic!';
      progressColor = Colors.green;
    } else if (percent >= 50) {
      titleMessage = 'Good Job! 👍';
      subtitleMessage = 'Great effort, you passed the quiz!';
      progressColor = Colors.orange;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  titleMessage,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  subtitleMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),

              // Circular progress score indicator
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: attempt.score / attempt.totalQuestions,
                        strokeWidth: 16,
                        backgroundColor: progressColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: GoogleFonts.inter(
                            textStyle: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                        ),
                        Text(
                          '${attempt.score} of ${attempt.totalQuestions} Correct',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Quizzes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
