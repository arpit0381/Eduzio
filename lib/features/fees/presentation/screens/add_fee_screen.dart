import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../student/presentation/controllers/student_controller.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';
import '../controllers/fees_controller.dart';

class AddFeeScreen extends ConsumerStatefulWidget {
  const AddFeeScreen({super.key});

  @override
  ConsumerState<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends ConsumerState<AddFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  String? _selectedStudentId;
  String? _selectedBatchId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _submitFee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      setState(() {
        _errorMessage = 'Please select a student';
      });
      return;
    }
    if (_selectedDueDate == null) {
      setState(() {
        _errorMessage = 'Please select a due date';
      });
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount greater than zero';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(feesControllerProvider.notifier).addFeeRecord(
            studentId: _selectedStudentId!,
            batchId: _selectedBatchId,
            amount: amount,
            dueDate: _selectedDueDate!,
            remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fee record created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save fee: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);
    final batchesAsync = ref.watch(batchesListProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fee Record'),
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
                      Icon(LucideIcons.creditCard, color: colors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Create a fee record/due invoice for a student. Once created, they can view their status and make payments.',
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

              // Student Dropdown
              studentsAsync.when(
                data: (students) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Select Student',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    items: students.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.profile.id,
                        child: Text(s.profile.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStudentId = val;
                      });
                    },
                    validator: (val) => val == null ? 'Student selection is required' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading students: $err'),
              ),
              const SizedBox(height: 16),

              // Batch Dropdown
              batchesAsync.when(
                data: (batches) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedBatchId,
                    decoration: const InputDecoration(
                      labelText: 'Batch (Optional)',
                      prefixIcon: Icon(LucideIcons.graduationCap),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Specific Batch'),
                      ),
                      ...batches.map((b) {
                        return DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(b.name),
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
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (INR)',
                  prefixIcon: Icon(LucideIcons.indianRupee),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(val.trim());
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Due Date Picker
              InkWell(
                onTap: _selectDueDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDueDate == null
                                ? 'Select Due Date'
                                : DateFormat('dd MMMM yyyy').format(_selectedDueDate!),
                            style: TextStyle(
                              color: _selectedDueDate == null
                                  ? colors.onSurfaceVariant.withValues(alpha: 0.6)
                                  : colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Icon(LucideIcons.chevronRight, color: colors.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Invoice Details',
                  prefixIcon: Icon(LucideIcons.alignLeft),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submitFee,
                      icon: const Icon(LucideIcons.save),
                      label: const Text('Add Fee Record'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
