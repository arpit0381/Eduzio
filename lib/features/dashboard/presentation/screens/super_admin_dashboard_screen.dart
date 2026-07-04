import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    int crossAxisCount = 1;
    if (size.width > 1200) {
      crossAxisCount = 3;
    } else if (size.width > 600) {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
            Card(
              color: colors.tertiaryContainer.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Overview',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Manage all registered institutes across the Eduzio platform.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onTertiaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.admin_panel_settings, size: 64, color: colors.tertiary.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            Text(
              'Platform Stats',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSizes.md,
              mainAxisSpacing: AppSizes.md,
              childAspectRatio: 2.0,
              children: [
                _buildStatCard(context, 'Total Institutes', '45', Icons.business, Colors.blue),
                _buildStatCard(context, 'Total Users', '12,400', Icons.people, Colors.teal),
                _buildStatCard(context, 'Active Sessions', '890', Icons.stacked_line_chart, Colors.orange),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            Text(
              'Recent Institutes',
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
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.surfaceContainerHighest,
                      child: const Icon(Icons.business_outlined),
                    ),
                    title: Text('Institute ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('inst${index + 1}.eduzio.in'),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      onPressed: () {},
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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: AppSizes.sm),
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
