import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Collected', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('₹1,45,000', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Outstanding', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('₹38,000', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Section: Outstanding Dues
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Collections',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.campaign, size: 18),
                  label: const Text('Remind All Dues'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                final studentNames = ['Kabir Singh', 'Diya Sen', 'Ananya Patel'];
                final batches = ['Class 12 - Physics', 'IIT-JEE Crash Course', 'Class 12 - Chemistry'];
                final dueAmounts = ['₹4,500', '₹12,000', '₹3,500'];
                final dueDates = ['June 25, 2026', 'July 01, 2026', 'June 28, 2026'];

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: ListTile(
                    title: Text(studentNames[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Batch: ${batches[index]} | Due: ${dueDates[index]}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dueAmounts[index],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            minimumSize: const Size(80, 36),
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                          ),
                          child: const Text('Record Pay'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_card),
        label: const Text('Create Structure'),
      ),
    );
  }
}
