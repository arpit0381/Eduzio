import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/sizes.dart';
import '../controllers/dashboard_controller.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;


    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Card(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello there!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Ready for your classes today? Keep up the good work!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.auto_awesome, size: 64, color: colors.primary.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            ref.watch(studentDashboardStatsProvider).when(
              data: (stats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Performance / Quick Stats
                    Text(
                      'My Progress',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStudentStat(
                            context,
                            'Attendance',
                            '${stats.attendancePercentage.toStringAsFixed(0)}%',
                            Icons.fact_check,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: _buildStudentStat(
                            context,
                            'Pending Homework',
                            '${stats.pendingHomework}',
                            Icons.assignment,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Enrolled Batches
                    Text(
                      'Enrolled Batches',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Card(
                      child: stats.enrolledBatches.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(AppSizes.lg),
                            child: Center(child: Text('No enrolled batches found.')),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stats.enrolledBatches.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final batch = stats.enrolledBatches[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colors.primaryContainer,
                                  child: Icon(Icons.book, color: colors.primary, size: 20),
                                ),
                                title: Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Code: ${batch.code}'),
                                trailing: FilledButton.tonal(
                                  onPressed: () {},
                                  child: const Text('View'),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentStat(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: AppSizes.iconMd),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
