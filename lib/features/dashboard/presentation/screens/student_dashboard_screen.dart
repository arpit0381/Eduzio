import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/constants/colors.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    // Dynamic grid columns
    int gridCount = 1;
    if (size.width > 900) {
      gridCount = 3;
    } else if (size.width > 600) {
      gridCount = 2;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apple Health style dynamic greeting header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to Learn',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                  ),
                  child: Icon(LucideIcons.bell, color: colors.onSurface, size: 20),
                ),
              ],
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            // Main stats & features grid
            ref.watch(studentDashboardStatsProvider).when(
              data: (stats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apple Health Asymmetrical Grid Layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 800;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Large Circular Attendance Card
                            Expanded(
                              flex: isDesktop ? 3 : 1,
                              child: _buildAttendanceCard(context, stats.attendancePercentage),
                            ),
                            if (isDesktop) const SizedBox(width: 24),
                            if (!isDesktop) const SizedBox(height: 16),
                            
                            // Small metrics (Homework & Achievements)
                            Expanded(
                              flex: isDesktop ? 2 : 1,
                              child: Column(
                                children: [
                                  _buildMetricCard(
                                    context,
                                    'Pending Homework',
                                    '${stats.pendingHomework}',
                                    'Due this week',
                                    LucideIcons.clock,
                                    AppColors.pastelOrange,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildMetricCard(
                                    context,
                                    'Achievements',
                                    '4 Badges',
                                    'Keep going!',
                                    LucideIcons.award,
                                    AppColors.pastelGreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),

                    // Batches & Schedule Section
                    Text(
                      'Enrolled Batches',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    stats.enrolledBatches.isEmpty
                        ? _buildEmptyState(context, 'No enrolled batches found.')
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.4,
                            ),
                            itemCount: stats.enrolledBatches.length,
                            itemBuilder: (context, index) {
                              final batch = stats.enrolledBatches[index];
                              return _buildBatchCard(context, batch.name, batch.code);
                            },
                          ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                  ],
                );
              },
              loading: () => _buildShimmer(context),
              error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: colors.error))),
            ),
          ],
        ),
      ),
    );
  }

  // Apple Health Circular Progress Card
  Widget _buildAttendanceCard(BuildContext context, double percentage) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: AppColors.pastelPurple,
      shadowColor: AppColors.pastelPurpleDark.withValues(alpha: 0.2),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                Icon(LucideIcons.activity, color: colors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          textStyle: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have attended almost all classes this month.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 10,
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      'Class',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Clean Metric Cards
  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color bgColor,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: bgColor,
      shadowColor: bgColor.withValues(alpha: 0.2),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pillBlack,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      textStyle: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium Batch Cards
  Widget _buildBatchCard(BuildContext context, String name, String code) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.bookOpen, color: colors.primary, size: 20),
                ),
                Text(
                  code,
                  style: GoogleFonts.inter(
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Active Curriculum',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(LucideIcons.layers, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
