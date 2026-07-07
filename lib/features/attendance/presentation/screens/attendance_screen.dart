import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/sizes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../controllers/attendance_controller.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isStudent = user.role == UserProfileRole.student;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudent ? 'My Attendance' : 'Attendance Dashboard'),
        centerTitle: false,
      ),
      body: isStudent
          ? const StudentAttendanceCalendarView()
          : _buildAdminView(context, theme, colors),
    );
  }

  Widget _buildAdminView(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Intro
              Text(
                'Manage Student Attendance',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Record student attendance daily or analyze batch performance statistics.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: SvgPicture.asset(
                  'public/undraw_reading-time_jva3.svg',
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 36),

              // Grid Menu Layout
              Builder(
                builder: (context) {
                  final isMobile = getValueForScreenType<bool>(
                    context: context,
                    mobile: true,
                    tablet: false,
                    desktop: false,
                  );
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                    children: [
                      // Card 1: Mark Attendance
                      isMobile 
                        ? _buildMenuCard(
                            context: context,
                            title: 'Mark Attendance',
                            description: 'Select a batch and date to record present/absent/late registers.',
                            icon: LucideIcons.clipboardCheck,
                            color: colors.primary,
                            onTap: () => context.go('/attendance/take'),
                          )
                        : Expanded(
                            child: _buildMenuCard(
                              context: context,
                              title: 'Mark Attendance',
                              description: 'Select a batch and date to record present/absent/late registers.',
                              icon: LucideIcons.clipboardCheck,
                              color: colors.primary,
                              onTap: () => context.go('/attendance/take'),
                            ),
                          ),
                      if (!isMobile) const SizedBox(width: 16) else const SizedBox(height: 16),
                      // Card 2: QR Scanner
                      isMobile
                        ? _buildMenuCard(
                            context: context,
                            title: 'QR ID Card Scan',
                            description: 'Scan student ID card QR codes for instantaneous daily check-ins.',
                            icon: LucideIcons.qrCode,
                            color: Colors.orange,
                            onTap: () => context.go('/attendance/scan'),
                          )
                        : Expanded(
                            child: _buildMenuCard(
                              context: context,
                              title: 'QR ID Card Scan',
                              description: 'Scan student ID card QR codes for instantaneous daily check-ins.',
                              icon: LucideIcons.qrCode,
                              color: Colors.orange,
                              onTap: () => context.go('/attendance/scan'),
                            ),
                          ),
                      if (!isMobile) const SizedBox(width: 16) else const SizedBox(height: 16),
                      // Card 3: Analytics & Reports
                      isMobile
                        ? _buildMenuCard(
                            context: context,
                            title: 'Reports & Stats',
                            description: 'Generate monthly attendance reports, view charts and analyze individual stats.',
                            icon: LucideIcons.barChart3,
                            color: Colors.teal,
                            onTap: () => context.go('/attendance/reports'),
                          )
                        : Expanded(
                            child: _buildMenuCard(
                              context: context,
                              title: 'Reports & Stats',
                              description: 'Generate monthly attendance reports, view charts and analyze individual stats.',
                              icon: LucideIcons.barChart3,
                              color: Colors.teal,
                              onTap: () => context.go('/attendance/reports'),
                            ),
                          ),
                    ],
                  );
                },
              ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Action Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 14, color: color),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class StudentAttendanceCalendarView extends ConsumerStatefulWidget {
  const StudentAttendanceCalendarView({super.key});

  @override
  ConsumerState<StudentAttendanceCalendarView> createState() => _StudentAttendanceCalendarViewState();
}

class _StudentAttendanceCalendarViewState extends ConsumerState<StudentAttendanceCalendarView> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;

  List<DateTime> _generateDaysInMonth(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    final daysCount = lastDayOfMonth.day;
    final firstDayWeekday = firstDayOfMonth.weekday;
    final paddingDaysStart = firstDayWeekday == 7 ? 0 : firstDayWeekday;

    final List<DateTime> days = [];

    // Previous month padding
    final prevMonthLastDay = DateTime(monthDate.year, monthDate.month, 0);
    for (int i = paddingDaysStart - 1; i >= 0; i--) {
      days.add(DateTime(monthDate.year, monthDate.month - 1, prevMonthLastDay.day - i));
    }

    // Current month days
    for (int i = 1; i <= daysCount; i++) {
      days.add(DateTime(monthDate.year, monthDate.month, i));
    }

    // Next month padding
    final totalCells = ((days.length / 7).ceil()) * 7;
    final paddingDaysEnd = totalCells - days.length;
    for (int i = 1; i <= paddingDaysEnd; i++) {
      days.add(DateTime(monthDate.year, monthDate.month + 1, i));
    }

    return days;
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + increment, 1);
      _selectedDate = null;
    });
  }

  Map<String, dynamic> _calculateMonthlyStats(List<StudentAttendanceLog> logs, DateTime month) {
    final monthlyLogs = logs.where((log) =>
        log.record.date.year == month.year &&
        log.record.date.month == month.month).toList();

    final total = monthlyLogs.length;
    final present = monthlyLogs.where((l) => l.record.status == AttendanceStatus.present).length;
    final late = monthlyLogs.where((l) => l.record.status == AttendanceStatus.late).length;
    final leave = monthlyLogs.where((l) => l.record.status == AttendanceStatus.leave).length;
    final absent = monthlyLogs.where((l) => l.record.status == AttendanceStatus.absent).length;

    final attended = present + late + leave;
    final double percentage = total > 0 ? (attended / total) * 100 : 100.0;

    return {
      'total': total,
      'present': present,
      'late': late,
      'leave': leave,
      'absent': absent,
      'percentage': percentage,
      'logs': monthlyLogs,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final logsAsync = ref.watch(studentAttendanceLogsProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: colors.error))),
      data: (logs) {
        final monthlyStats = _calculateMonthlyStats(logs, _currentMonth);
        final generatedDays = _generateDaysInMonth(_currentMonth);

        // Find selected day's logs
        final List<StudentAttendanceLog> selectedDayLogs = _selectedDate == null
            ? []
            : logs.where((l) =>
                l.record.date.year == _selectedDate!.year &&
                l.record.date.month == _selectedDate!.month &&
                l.record.date.day == _selectedDate!.day).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Builder(
                builder: (context) {
                  final isDesktop = getValueForScreenType<bool>(
                    context: context,
                    mobile: false,
                    tablet: false,
                    desktop: true,
                  );

                  final calendarCard = _buildCalendarCard(theme, colors, generatedDays, logs);
                  final statsAndDetailsCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatsReportCard(theme, colors, monthlyStats),
                      const SizedBox(height: 24),
                      _buildDetailsCard(theme, colors, selectedDayLogs),
                    ],
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: calendarCard),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: statsAndDetailsCol),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      calendarCard,
                      const SizedBox(height: 24),
                      statsAndDetailsCol,
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarCard(
    ThemeData theme,
    ColorScheme colors,
    List<DateTime> days,
    List<StudentAttendanceLog> allLogs,
  ) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Calendar Month Navigation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekdays Header Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    weekdays[index],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == _currentMonth.month;
                final isToday = DateUtils.isSameDay(day, DateTime.now());
                final isSelected = _selectedDate != null && DateUtils.isSameDay(day, _selectedDate);

                // Find log for this day
                final matchingLogs = allLogs.where((l) => DateUtils.isSameDay(l.record.date, day)).toList();
                final hasLog = matchingLogs.isNotEmpty;
                final status = hasLog ? matchingLogs.first.record.status : null;

                Color cellColor = Colors.transparent;
                Color textColor = isCurrentMonth
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.25);
                FontWeight fontWeight = FontWeight.normal;

                if (isCurrentMonth && hasLog) {
                  fontWeight = FontWeight.bold;
                  if (status == AttendanceStatus.present) {
                    cellColor = Colors.green.withValues(alpha: 0.12);
                    textColor = Colors.green.shade800;
                  } else if (status == AttendanceStatus.late) {
                    cellColor = Colors.orange.withValues(alpha: 0.12);
                    textColor = Colors.orange.shade800;
                  } else if (status == AttendanceStatus.leave) {
                    cellColor = Colors.blue.withValues(alpha: 0.12);
                    textColor = Colors.blue.shade800;
                  } else if (status == AttendanceStatus.absent) {
                    cellColor = Colors.red.withValues(alpha: 0.12);
                    textColor = Colors.red.shade800;
                  }
                }

                return Tooltip(
                  message: hasLog
                      ? '${matchingLogs.first.batchName}: ${status?.key.toUpperCase()}'
                      : 'No entry',
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = day;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: colors.primary, width: 2.5)
                            : (isToday
                                ? Border.all(color: colors.primary.withValues(alpha: 0.4), width: 1.5)
                                : null),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: fontWeight,
                              ),
                            ),
                          ),
                          if (isCurrentMonth && hasLog)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: textColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsReportCard(
    ThemeData theme,
    ColorScheme colors,
    Map<String, dynamic> stats,
  ) {
    final double percentage = stats['percentage'] as double;
    final int present = stats['present'] as int;
    final int lateCount = stats['late'] as int;
    final int leave = stats['leave'] as int;
    final int absent = stats['absent'] as int;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Statistics Report',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Rate Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Attendance Rate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 10,
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentage >= 75
                                ? Colors.green
                                : (percentage >= 50 ? Colors.orange : Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    textStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics Grid Details
            Row(
              children: [
                Expanded(child: _buildMiniStat(theme, colors, 'Present', '$present', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStat(theme, colors, 'Late', '$lateCount', Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMiniStat(theme, colors, 'Excused', '$leave', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStat(theme, colors, 'Absent', '$absent', Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    ThemeData theme,
    ColorScheme colors,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    ThemeData theme,
    ColorScheme colors,
    List<StudentAttendanceLog> dayLogs,
  ) {
    if (_selectedDate == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outline.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Select a date to view check-in details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate!);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details for Day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (dayLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No check-ins recorded on this date.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayLogs.length,
                itemBuilder: (context, index) {
                  final log = dayLogs[index];
                  final isPresent = log.record.status == AttendanceStatus.present;
                  final isLate = log.record.status == AttendanceStatus.late;
                  final isLeave = log.record.status == AttendanceStatus.leave;
                  final isAbsent = log.record.status == AttendanceStatus.absent;

                  Color statusColor = colors.primary;
                  String statusText = 'Unknown';

                  if (isPresent) {
                    statusColor = Colors.green;
                    statusText = 'Present';
                  } else if (isLate) {
                    statusColor = Colors.orange;
                    statusText = 'Late';
                  } else if (isLeave) {
                    statusColor = Colors.blue;
                    statusText = 'On Leave';
                  } else if (isAbsent) {
                    statusColor = Colors.red;
                    statusText = 'Absent';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outline.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.batchName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Batch Code: ${log.batchCode}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        if (log.record.remarks != null && log.record.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Remarks: ${log.record.remarks}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
