import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

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
                    '85%',
                    Icons.fact_check,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _buildStudentStat(
                    context,
                    'Pending Homework',
                    '2',
                    Icons.assignment,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Today's Classes
            Text(
              'Today\'s Classes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final subjects = ['Physics', 'Mathematics'];
                  final times = ['10:00 AM - 11:30 AM', '12:00 PM - 01:30 PM'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      child: Icon(Icons.book, color: colors.primary, size: 20),
                    ),
                    title: Text(subjects[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(times[index]),
                    trailing: FilledButton.tonal(
                      onPressed: () {},
                      child: const Text('Join'),
                    ),
                  );
                },
              ),
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
