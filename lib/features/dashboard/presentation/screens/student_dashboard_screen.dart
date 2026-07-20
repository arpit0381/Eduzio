import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dashboard_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/dashboard_stats.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Dynamic grid columns
    final gridCount = getValueForScreenType<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    final horizontalPadding = getValueForScreenType<double>(
      context: context,
      mobile: 16,
      tablet: 24,
      desktop: 24,
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apple Health style dynamic greeting header
            Builder(
              builder: (context) {
                final isMobile = getValueForScreenType<bool>(
                  context: context,
                  mobile: true,
                  tablet: false,
                  desktop: false,
                );
                return Card(
                  elevation: 0,
                  color: colors.primaryContainer.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: colors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ref.watch(authStateProvider).when(
                                data: (profile) => Text(
                                  'Welcome back, ${profile?.name ?? "Student"}! 👋',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                loading: () => Text(
                                  'Welcome back! 👋',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                error: (_, s) => Text(
                                  'Welcome back! 👋',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your road to knowledge is bright today! Track your course progress, pending homework, and check in on your attendance records below.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: SvgPicture.asset(
                              'public/undraw_road-to-knowledge_ufma.svg',
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            // Main stats & features grid
            ref.watch(studentDashboardStatsProvider).when(
              data: (stats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apple Health Asymmetrical Grid Layout
                    Builder(
                      builder: (context) {
                        final isMobile = getValueForScreenType<bool>(
                          context: context,
                          mobile: true,
                          tablet: false,
                          desktop: false,
                        );
                        if (isMobile) {
                          // Stack vertically on mobile
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildAttendanceCard(context, stats.attendancePercentage),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      context,
                                      'Pending Homework',
                                      '${stats.pendingHomework}',
                                      'Due this week',
                                      LucideIcons.clock,
                                      Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      context,
                                      'Achievements',
                                      '4 Badges',
                                      'Keep going!',
                                      LucideIcons.award,
                                      colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        // Desktop/Tablet: side by side
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildAttendanceCard(context, stats.attendancePercentage),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildMetricCard(
                                    context,
                                    'Pending Homework',
                                    '${stats.pendingHomework}',
                                    'Due this week',
                                    LucideIcons.clock,
                                    Colors.amber,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildMetricCard(
                                    context,
                                    'Achievements',
                                    '4 Badges',
                                    'Keep going!',
                                    LucideIcons.award,
                                    colors.primary,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enrolled Batches',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const _JoinBatchDialog(),
                            );
                          },
                          icon: const Icon(LucideIcons.plusCircle, size: 18),
                          label: const Text('Join Batch'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
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
                              childAspectRatio: 1.12,
                            ),
                            itemCount: stats.enrolledBatches.length,
                            itemBuilder: (context, index) {
                              final batch = stats.enrolledBatches[index];
                              return _buildBatchCard(context, batch);
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
      child: InkWell(
        onTap: () => context.go('/attendance'),
        borderRadius: BorderRadius.circular(24),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Attendance Calendar',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.arrowRight, size: 14, color: colors.primary),
                ],
              ),
            ],
          ),
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
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor, size: 22),
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
  Widget _buildBatchCard(BuildContext context, DashboardBatchItem batch) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final double attendanceVal = batch.attendancePercentage ?? 100.0;
    final int total = batch.totalClasses ?? 0;
    final int attended = batch.attendedClasses ?? 0;

    // Color based on compliance
    Color progressColor = colors.primary;
    if (attendanceVal >= 75) {
      progressColor = Colors.green;
    } else if (attendanceVal >= 50) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.bookOpen, color: colors.primary, size: 16),
                ),
                Text(
                  batch.code,
                  style: GoogleFonts.inter(
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              batch.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${attendanceVal.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        textStyle: theme.textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: total > 0 ? (attended / total) : 1.0,
                    color: progressColor,
                    backgroundColor: progressColor.withValues(alpha: 0.1),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total > 0 ? '$attended of $total classes' : 'No classes marked yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    fontSize: 10,
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
    final colors = theme.colorScheme;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            SvgPicture.asset(
              'public/undraw_studying-science_kk9e.svg',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
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

class _JoinBatchDialog extends ConsumerStatefulWidget {
  const _JoinBatchDialog();
  @override
  ConsumerState<_JoinBatchDialog> createState() => _JoinBatchDialogState();
}

class _JoinBatchDialogState extends ConsumerState<_JoinBatchDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinBatch() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a batch code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final controller = ref.read(joinBatchControllerProvider);
      await controller.joinBatch(code);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined batch!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Batch'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the batch code provided by your teacher.'),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Batch Code',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _joinBatch,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Join'),
        ),
      ],
    );
  }
}
