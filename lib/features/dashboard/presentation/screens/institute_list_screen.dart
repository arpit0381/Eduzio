import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/sizes.dart';
import '../controllers/dashboard_controller.dart';
import 'package:go_router/go_router.dart';

class InstituteListScreen extends ConsumerWidget {
  const InstituteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    int crossAxisCount = 1;
    if (size.width > 1200) {
      crossAxisCount = 3;
    } else if (size.width > 800) {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Institutes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Institute',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Institute coming soon!')),
              );
            },
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: ref.watch(allInstitutesProvider).when(
        data: (institutes) {
          if (institutes.isEmpty) {
            return _buildEmptyState(context);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSizes.md,
              mainAxisSpacing: AppSizes.md,
              childAspectRatio: 2.5,
            ),
            itemCount: institutes.length,
            itemBuilder: (context, index) {
              final inst = institutes[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            child: Icon(Icons.business, color: colors.primary),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inst.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  inst.subdomain,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.go('/institutes/${inst.id}');
                              },
                              icon: const Icon(Icons.visibility, size: 18),
                              label: const Text('View Details'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: AppSizes.md),
              Text('Failed to load institutes', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSizes.sm),
              Text(err.toString(), style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSizes.md),
              FilledButton.tonal(
                onPressed: () => ref.refresh(allInstitutesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: colors.outline),
          const SizedBox(height: AppSizes.md),
          Text(
            'No Institutes Found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'There are no institutes registered on the platform yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
