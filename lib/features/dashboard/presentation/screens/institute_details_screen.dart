import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/sizes.dart';
import '../controllers/dashboard_controller.dart';

class InstituteDetailsScreen extends ConsumerWidget {
  final String orgId;

  const InstituteDetailsScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    int statCrossAxisCount = 1;
    if (size.width > 1200) {
      statCrossAxisCount = 4;
    } else if (size.width > 800) {
      statCrossAxisCount = 3;
    } else if (size.width > 600) {
      statCrossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute Details'),
      ),
      body: ref.watch(instituteDetailsProvider(orgId)).when(
        data: (details) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    child: Wrap(
                      spacing: AppSizes.xl,
                      runSpacing: AppSizes.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colors.primary,
                          child: Icon(Icons.business, size: 40, color: colors.onPrimary),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                details.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Wrap(
                                spacing: AppSizes.lg,
                                runSpacing: AppSizes.xs,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.link, size: 16, color: colors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        details.subdomain,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: colors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Joined ${DateFormat.yMMMd().format(details.createdAt)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                Text(
                  'Overview',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.md),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: statCrossAxisCount,
                  crossAxisSpacing: AppSizes.md,
                  mainAxisSpacing: AppSizes.md,
                  childAspectRatio: size.width > 600 ? 2.5 : 3.0,
                  children: [
                    _buildStatCard(context, 'Total Users', '${details.totalUsers}', Icons.people, Colors.blue),
                    _buildStatCard(context, 'Students', '${details.totalStudents}', Icons.school, Colors.green),
                    _buildStatCard(context, 'Teachers', '${details.totalTeachers}', Icons.co_present, Colors.orange),
                    _buildStatCard(context, 'Batches', '${details.totalBatches}', Icons.class_, Colors.purple),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Admin Info
                Text(
                  'Administrator Contact',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.md),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Wrap(
                      spacing: AppSizes.md,
                      runSpacing: AppSizes.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colors.secondaryContainer,
                          child: Icon(Icons.person, color: colors.onSecondaryContainer),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 150),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                details.adminName ?? 'No Admin Found',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                details.adminEmail ?? 'No Email',
                                style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.email),
                          label: const Text('Contact'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading details: $err', style: TextStyle(color: colors.error)),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
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
}
