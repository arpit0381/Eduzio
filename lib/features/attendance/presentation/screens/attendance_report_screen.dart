import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/attendance_record.dart';
import '../controllers/attendance_controller.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';
import '../../../../shared/widgets/responsive_layout.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends ConsumerState<AttendanceReportScreen> {
  String? _selectedBatchId;
  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        centerTitle: false,
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
                        'Create a batch to view attendance statistics and reports.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (_selectedBatchId == null && batches.isNotEmpty) {
            _selectedBatchId = batches.first.id;
          }

          return ResponsiveLayout(
            mobile: _buildContent(context, batches),
            tablet: _buildContent(context, batches),
            desktop: _buildContent(context, batches, isDesktop: true),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<dynamic> batches, {bool isDesktop = false}) {

    return Column(
      children: [
        // Filter Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBatchId,
                    decoration: const InputDecoration(
                      labelText: 'Batch',
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
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Month Picker
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () async {
                      // Custom month picker or use standard year picker to limit
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth,
                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                        lastDate: DateTime.now(),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedMonth = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Reports View
        Expanded(
          child: _selectedBatchId == null
              ? const Center(child: Text('Select a batch.'))
              : _buildReportData(context, _selectedBatchId!),
        ),
      ],
    );
  }

  Widget _buildReportData(BuildContext context, String batchId) {
    final studentsAsync = ref.watch(batchStudentsProvider(batchId));
    final attendanceAsync = ref.watch(batchAttendanceReportProvider(batchId));
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
          error: (err, stack) => Center(child: Text('Error loading attendance data: $err')),
          data: (allRecords) {
            // Filter records for the selected month & year
            final monthRecords = allRecords.where((record) {
              return record.date.year == _selectedMonth.year &&
                  record.date.month == _selectedMonth.month;
            }).toList();

            // Calculate aggregate statistics
            int totalPresent = 0;
            int totalAbsent = 0;
            int totalLate = 0;
            int totalLeave = 0;

            for (final r in monthRecords) {
              switch (r.status) {
                case AttendanceStatus.present:
                  totalPresent++;
                  break;
                case AttendanceStatus.absent:
                  totalAbsent++;
                  break;
                case AttendanceStatus.late:
                  totalLate++;
                  break;
                case AttendanceStatus.leave:
                  totalLeave++;
                  break;
              }
            }

            final totalMarked = monthRecords.length;
            final presentRate = totalMarked > 0 
                ? ((totalPresent + totalLate) / totalMarked * 100).toStringAsFixed(1)
                : '0.0';

            // Student level aggregation maps
            final studentPresentCount = <String, int>{};
            final studentAbsentCount = <String, int>{};
            final studentLateCount = <String, int>{};
            final studentLeaveCount = <String, int>{};

            for (final student in students) {
              final studentId = student.profile.id;
              studentPresentCount[studentId] = 0;
              studentAbsentCount[studentId] = 0;
              studentLateCount[studentId] = 0;
              studentLeaveCount[studentId] = 0;
            }

            // Group records by student
            for (final r in monthRecords) {
              if (studentPresentCount.containsKey(r.studentId)) {
                switch (r.status) {
                  case AttendanceStatus.present:
                    studentPresentCount[r.studentId] = studentPresentCount[r.studentId]! + 1;
                    break;
                  case AttendanceStatus.absent:
                    studentAbsentCount[r.studentId] = studentAbsentCount[r.studentId]! + 1;
                    break;
                  case AttendanceStatus.late:
                    studentLateCount[r.studentId] = studentLateCount[r.studentId]! + 1;
                    break;
                  case AttendanceStatus.leave:
                    studentLeaveCount[r.studentId] = studentLeaveCount[r.studentId]! + 1;
                    break;
                }
              }
            }

            final filteredStudents = students.where((s) {
              return s.profile.name.toLowerCase().contains(_searchQuery);
            }).toList();

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Stats Row Cards
                Row(
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Present Rate',
                      value: '$presentRate%',
                      color: Colors.green,
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      context: context,
                      title: 'Total Records',
                      value: '$totalMarked',
                      color: theme.colorScheme.primary,
                      icon: Icons.assessment,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Chart Card
                if (totalMarked > 0)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Distribution',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: totalPresent.toDouble(),
                                    title: 'P: $totalPresent',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: totalAbsent.toDouble(),
                                    title: 'A: $totalAbsent',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.orange,
                                    value: totalLate.toDouble(),
                                    title: 'L: $totalLate',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.blue,
                                    value: totalLeave.toDouble(),
                                    title: 'LV: $totalLeave',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem('Present', Colors.green),
                              _buildLegendItem('Absent', Colors.red),
                              _buildLegendItem('Late', Colors.orange),
                              _buildLegendItem('Leave', Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.pie_chart_outline, size: 48, color: theme.hintColor),
                            const SizedBox(height: 12),
                            const Text('No attendance marked for this month.'),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Search Box
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search student report...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Students Report Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Student Name',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'P / L / LV / A',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Rate %',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // List of Students Reports
                ...filteredStudents.map((student) {
                  final studentId = student.profile.id;
                  final p = studentPresentCount[studentId] ?? 0;
                  final a = studentAbsentCount[studentId] ?? 0;
                  final l = studentLateCount[studentId] ?? 0;
                  final lv = studentLeaveCount[studentId] ?? 0;

                  final studentTotal = p + a + l + lv;
                  final studentRate = studentTotal > 0
                      ? ((p + l) / studentTotal * 100).toStringAsFixed(0)
                      : '-';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.profile.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                student.profile.email,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$p / $l / $lv / $a',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            studentRate == '-' ? '-' : '$studentRate%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: studentRate == '-' 
                                  ? theme.hintColor 
                                  : int.parse(studentRate) >= 75 
                                      ? Colors.green 
                                      : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
