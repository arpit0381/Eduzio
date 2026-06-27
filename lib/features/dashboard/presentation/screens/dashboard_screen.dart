import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    // Calculate grid columns dynamically based on screen width
    int crossAxisCount = 1;
    if (size.width > 1200) {
      crossAxisCount = 4;
    } else if (size.width > 600) {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            // Header Card
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
                            'Welcome to Eduzio!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Here is what is happening at your institute today.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.school, size: 64, color: colors.primary.withValues(alpha: 0.2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Statistics Section
            Text(
              'Quick Stats',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSizes.md,
              mainAxisSpacing: AppSizes.md,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(context, 'Total Students', '342', Icons.people, colors.primary),
                _buildStatCard(context, 'Active Batches', '12', Icons.class_, Colors.teal),
                _buildStatCard(context, 'Today\'s Attendance', '94%', Icons.check_circle, Colors.green),
                _buildStatCard(context, 'Fees Collected', '₹1.2L', Icons.currency_rupee, Colors.orange),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Main Columns (Schedule and Recent Activity)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Classes (Takes up remaining width or full width on mobile)
                Expanded(
                  flex: size.width > 900 ? 2 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Classes',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final times = ['09:00 AM - 10:30 AM', '11:00 AM - 12:30 PM', '02:00 PM - 03:30 PM'];
                            final subjects = ['Physics - Batch A', 'Chemistry - Batch B', 'Mathematics - Batch C'];
                            final rooms = ['Classroom 1', 'Classroom 3', 'Classroom 2'];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colors.surfaceContainerHighest,
                                child: Text('${index + 1}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(subjects[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${times[index]} | ${rooms[index]}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacing
                if (size.width > 900) const SizedBox(width: AppSizes.lg),

                // Quick Actions (Sidebar on Desktop/Tablet)
                if (size.width > 900)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildActionButton(context, 'Take Attendance', Icons.fact_check, colors.primary),
                                const SizedBox(height: AppSizes.sm),
                                _buildActionButton(context, 'Add New Student', Icons.person_add, colors.secondary),
                                const SizedBox(height: AppSizes.sm),
                                _buildActionButton(context, 'Create Homework', Icons.upload_file, Colors.blueGrey),
                                const SizedBox(height: AppSizes.sm),
                                _buildActionButton(context, 'Publish Notice', Icons.campaign, Colors.indigo),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Icon(icon, color: color, size: AppSizes.iconLg),
              ],
            ),
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

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSizes.md),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
