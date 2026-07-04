import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../domain/entities/attendance_record.dart';
import '../controllers/attendance_controller.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';
import '../../../student/domain/entities/student_detail.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  ConsumerState<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  String? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final Map<String, AttendanceStatus> _tempAttendance = {};
  final Map<String, String> _tempRemarks = {};

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        centerTitle: false,
        actions: [
          // Offline sync status banner or action
          Consumer(
            builder: (context, ref, child) {
              final syncState = ref.watch(syncControllerProvider);
              return syncState.maybeWhen(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                orElse: () => IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync Offline Data',
                  onPressed: () async {
                    final count = await ref.read(syncControllerProvider.notifier).triggerSync();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(count > 0 
                            ? 'Successfully synced $count records!' 
                            : 'No offline records to sync, or connection unavailable.'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading batches: $err')),
        data: (batches) {
          if (batches.isEmpty) {
            return Center(
              child: Card(
                elevation: 0,
                color: theme.colorScheme.errorContainer,
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'No Batches Available',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a batch before recording student attendance.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Automatically select first batch if none selected
          if (_selectedBatchId == null && batches.isNotEmpty) {
            _selectedBatchId = batches.first.id;
          }

          return _buildContent(context, batches);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<dynamic> batches) {
    final isMobile = getValueForScreenType<bool>(
      context: context,
      mobile: true,
      tablet: false,
      desktop: false,
    );

    return Column(
      children: [
        // Top Filter Panel
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Batch + Date picker row (or column on mobile)
                if (isMobile) ...[
                  // Batch dropdown full width
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBatchId,
                    decoration: const InputDecoration(
                      labelText: 'Select Batch',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: batches.map<DropdownMenuItem<String>>((b) {
                      return DropdownMenuItem<String>(
                        value: b.id,
                        child: Text('${b.name} (${b.code})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBatchId = val;
                        _tempAttendance.clear();
                        _tempRemarks.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Date picker full width
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar full width
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search student...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Bulk actions row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _bulkMarkAll(AttendanceStatus.present),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('All Present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _bulkMarkAll(AttendanceStatus.absent),
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          label: const Text('All Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Desktop / Tablet: horizontal layout
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBatchId,
                          decoration: const InputDecoration(
                            labelText: 'Select Batch',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          items: batches.map<DropdownMenuItem<String>>((b) {
                            return DropdownMenuItem<String>(
                              value: b.id,
                              child: Text('${b.name} (${b.code})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                              _tempAttendance.clear();
                              _tempRemarks.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () => _pickDate(context),
                          icon: const Icon(Icons.calendar_month),
                          label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search student...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _bulkMarkAll(AttendanceStatus.present),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('All Present'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _bulkMarkAll(AttendanceStatus.absent),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('All Absent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Students Grid/List
        Expanded(
          child: _selectedBatchId == null
              ? const Center(child: Text('Please select a batch.'))
              : _buildStudentsList(context, _selectedBatchId!, isMobile),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tempAttendance.clear();
        _tempRemarks.clear();
      });
    }
  }

  Widget _buildStudentsList(BuildContext context, String batchId, bool isMobile) {
    final studentsAsync = ref.watch(batchStudentsProvider(batchId));
    final attendanceAsync = ref.watch(attendanceListProvider((batchId: batchId, date: _selectedDate)));
    final theme = Theme.of(context);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading students: $err')),
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('No students enrolled in this batch.'));
        }

        return attendanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading attendance: $err')),
          data: (records) {
            // Seed our local temp maps with fetched database values if they aren't already set
            for (final record in records) {
              if (!_tempAttendance.containsKey(record.studentId)) {
                _tempAttendance[record.studentId] = record.status;
                if (record.remarks != null) {
                  _tempRemarks[record.studentId] = record.remarks!;
                }
              }
            }

            final filteredStudents = students.where((s) {
              return s.profile.name.toLowerCase().contains(_searchQuery) ||
                  (s.profile.email.toLowerCase().contains(_searchQuery));
            }).toList();

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final studentId = student.profile.id;
                      final currentStatus = _tempAttendance[studentId] ?? AttendanceStatus.present;
                      final remarks = _tempRemarks[studentId] ?? '';

                      if (isMobile) {
                        return _buildMobileStudentCard(theme, student, studentId, currentStatus, remarks);
                      }
                      return _buildDesktopStudentCard(theme, student, studentId, currentStatus, remarks);
                    },
                  ),
                ),

                // Save bottom bar
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final saveState = ref.watch(attendanceControllerProvider);
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => _saveAll(batchId, students),
                          child: saveState.maybeWhen(
                            loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            orElse: () => const Text(
                              'Save Attendance',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Mobile: compact vertical card ──
  Widget _buildMobileStudentCard(
    ThemeData theme,
    StudentDetail student,
    String studentId,
    AttendanceStatus currentStatus,
    String remarks,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar + Name + Remarks
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    student.profile.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.profile.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        student.profile.email,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    remarks.isNotEmpty ? Icons.comment : Icons.add_comment_outlined,
                    color: remarks.isNotEmpty ? theme.colorScheme.primary : theme.hintColor,
                    size: 20,
                  ),
                  tooltip: remarks.isNotEmpty ? remarks : 'Add Remarks',
                  onPressed: () => _showRemarksDialog(student.profile.name, studentId, remarks),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom row: Status toggle buttons (full width)
            SizedBox(
              width: double.infinity,
              child: ToggleButtons(
                isSelected: [
                  currentStatus == AttendanceStatus.present,
                  currentStatus == AttendanceStatus.absent,
                  currentStatus == AttendanceStatus.late,
                  currentStatus == AttendanceStatus.leave,
                ],
                onPressed: (index) {
                  setState(() {
                    _tempAttendance[studentId] = AttendanceStatus.values[index];
                  });
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: _getStatusColor(currentStatus),
                color: theme.hintColor,
                constraints: BoxConstraints.expand(
                  width: (MediaQuery.sizeOf(context).width - 96) / 4,
                  height: 36,
                ),
                children: const [
                  Text('Present', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Absent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Late', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop: horizontal card ──
  Widget _buildDesktopStudentCard(
    ThemeData theme,
    StudentDetail student,
    String studentId,
    AttendanceStatus currentStatus,
    String remarks,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                student.profile.name.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.profile.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    student.profile.email,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ToggleButtons(
                    isSelected: [
                      currentStatus == AttendanceStatus.present,
                      currentStatus == AttendanceStatus.absent,
                      currentStatus == AttendanceStatus.late,
                      currentStatus == AttendanceStatus.leave,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _tempAttendance[studentId] = AttendanceStatus.values[index];
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: _getStatusColor(currentStatus),
                    color: theme.hintColor,
                    constraints: BoxConstraints.expand(
                      width: (constraints.maxWidth - 5) / 4,
                      height: 38,
                    ),
                    children: const [
                      Text('P', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('LV', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                remarks.isNotEmpty ? Icons.comment : Icons.add_comment_outlined,
                color: remarks.isNotEmpty ? theme.colorScheme.primary : theme.hintColor,
              ),
              tooltip: remarks.isNotEmpty ? remarks : 'Add Remarks',
              onPressed: () => _showRemarksDialog(student.profile.name, studentId, remarks),
            ),
          ],
        ),
      ),
    );
  }

  void _bulkMarkAll(AttendanceStatus status) {
    final studentsAsync = ref.read(batchStudentsProvider(_selectedBatchId!));
    studentsAsync.whenData((students) {
      setState(() {
        for (final student in students) {
          _tempAttendance[student.profile.id] = status;
        }
      });
    });
  }

  void _showRemarksDialog(String studentName, String studentId, String currentRemarks) {
    final controller = TextEditingController(text: currentRemarks);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remarks for $studentName'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter attendance remarks (e.g. sick leave, informed late)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tempRemarks[studentId] = controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.leave:
        return Colors.blue;
    }
  }

  Future<void> _saveAll(String batchId, List<StudentDetail> students) async {
    final recordsToSave = students.map((s) {
      final studentId = s.profile.id;
      final status = _tempAttendance[studentId] ?? AttendanceStatus.present;
      final remarks = _tempRemarks[studentId];

      return AttendanceRecord(
        id: '', // Blank, generated by Supabase or mapped from Isar row local ID
        organizationId: '', // Filled in by repository implementation
        batchId: batchId,
        studentId: studentId,
        date: _selectedDate,
        status: status,
        remarks: remarks,
      );
    }).toList();

    try {
      await ref
          .read(attendanceControllerProvider.notifier)
          .saveAttendance(
            batchId: batchId,
            date: _selectedDate,
            records: recordsToSave,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: $e')),
        );
      }
    }
  }
}
