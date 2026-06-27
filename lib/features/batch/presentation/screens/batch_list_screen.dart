import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/sizes.dart';
import '../../domain/entities/batch.dart';
import '../controllers/batch_controller.dart';

class BatchListScreen extends ConsumerWidget {
  const BatchListScreen({super.key});

  void _showAddBatchDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Create New Batch'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name',
                    hintText: 'e.g. Class 12 - Physics A',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter batch name' : null,
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Code',
                    hintText: 'e.g. PHY-12-A',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter batch code' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final batch = Batch(
                    id: '',
                    organizationId: '',
                    name: nameController.text.trim(),
                    code: codeController.text.trim().toUpperCase(),
                    startDate: DateTime.now(),
                  );
                  try {
                    await ref.read(batchesListProvider.notifier).addBatch(batch);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save: ${e.toString()}'),
                          backgroundColor: colors.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Batch batch) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch'),
        content: Text('Are you sure you want to delete batch "${batch.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
            onPressed: () async {
              try {
                await ref.read(batchesListProvider.notifier).deleteBatch(batch.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e'), backgroundColor: colors.error),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final batchesAsync = ref.watch(batchesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(batchesListProvider),
          ),
        ],
      ),
      body: batchesAsync.when(
        data: (batches) {
          if (batches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.class_outlined, size: 64, color: colors.outline.withOpacity(0.5)),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'No Batches Yet',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Create your first classroom batch to assign subjects and students.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              batch.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              batch.code,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            batch.startDate != null
                                ? 'Started: ${batch.startDate!.day}/${batch.startDate!.month}/${batch.startDate!.year}'
                                : 'Start Date: N/A',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: colors.error),
                            tooltip: 'Delete Batch',
                            onPressed: () => _confirmDelete(context, ref, batch),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(130, 36),
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
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
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: AppSizes.md),
                Text('Error loading batches: $err', textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.md),
                ElevatedButton(
                  onPressed: () => ref.invalidate(batchesListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBatchDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Batch'),
      ),
    );
  }
}
