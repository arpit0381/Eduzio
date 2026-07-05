import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/sizes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
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
          ? _buildStudentView(context, ref, theme, colors)
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

  Widget _buildStudentView(BuildContext context, WidgetRef ref, ThemeData theme, ColorScheme colors) {
    final statsAsync = ref.watch(studentDashboardStatsProvider);
    final logsAsync = ref.watch(studentAttendanceLogsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Overview Header Card
              statsAsync.when(
                data: (stats) {
                  return Card(
                    elevation: 0,
                    color: colors.primaryContainer.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colors.primary.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attendance Overview',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  stats.attendancePercentage >= 75
                                      ? 'Excellent progress! Your attendance is in high compliance. Keep maintaining it.'
                                      : 'Attention: Your attendance is below the recommended 75% threshold. Please stay regular.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Circular indicator showing overall attendance
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 88,
                                height: 88,
                                child: CircularProgressIndicator(
                                  value: stats.attendancePercentage / 100,
                                  strokeWidth: 8,
                                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    stats.attendancePercentage >= 75
                                        ? Colors.green
                                        : (stats.attendancePercentage >= 50 ? Colors.orange : Colors.red),
                                  ),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Text(
                                '${stats.attendancePercentage.toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  textStyle: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => const SizedBox.shrink(),
              ).animate().fade(duration: 400.ms),
              
              const SizedBox(height: 32),

              // Log history title
              Text(
                'Recent Check-ins 📅',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'public/undraw_share-results_lfh5.svg',
                              height: 160,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No check-ins recorded yet.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your attendance logs will appear here once marked by a teacher.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isPresent = log.record.status == AttendanceStatus.present;
                      final isLate = log.record.status == AttendanceStatus.late;
                      final isLeave = log.record.status == AttendanceStatus.leave;
                      final isAbsent = log.record.status == AttendanceStatus.absent;

                      Color statusColor = colors.primary;
                      IconData statusIcon = LucideIcons.helpCircle;
                      String statusText = 'Unknown';

                      if (isPresent) {
                        statusColor = Colors.green;
                        statusIcon = LucideIcons.checkCircle2;
                        statusText = 'Present';
                      } else if (isLate) {
                        statusColor = Colors.orange;
                        statusIcon = LucideIcons.clock;
                        statusText = 'Late';
                      } else if (isLeave) {
                        statusColor = Colors.blue;
                        statusIcon = LucideIcons.calendarDays;
                        statusText = 'On Leave';
                      } else if (isAbsent) {
                        statusColor = Colors.red;
                        statusIcon = LucideIcons.xCircle;
                        statusText = 'Absent';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 20),
                          ),
                          title: Text(
                            DateFormat('EEEE, dd MMM yyyy').format(log.record.date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${log.batchName} (${log.batchCode})'),
                              if (log.record.remarks != null && log.record.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Note: ${log.record.remarks}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: colors.error))),
              ).animate().fade(delay: 100.ms),
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
