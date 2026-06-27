import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class BatchListScreen extends StatelessWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batches'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: 4,
        itemBuilder: (context, index) {
          final batchNames = ['Class 12 - Physics', 'Class 12 - Chemistry', 'Class 11 - Mathematics', 'IIT-JEE Crash Course'];
          final codes = ['PHY-12-A', 'CHEM-12-A', 'MATH-11-B', 'JEE-CRASH'];
          final studentCounts = [45, 42, 38, 55];
          final timings = ['09:00 AM - 10:30 AM (Mon, Wed, Fri)', '11:00 AM - 12:30 PM (Mon, Wed, Fri)', '02:00 PM - 03:30 PM (Tue, Thu, Sat)', '04:00 PM - 06:00 PM (Daily)'];

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
                      Text(
                        batchNames[index],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          codes[index],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16),
                      const SizedBox(width: AppSizes.xs),
                      Text('${studentCounts[index]} Students Enrolled'),
                      const SizedBox(width: AppSizes.md),
                      const Icon(Icons.school_outlined, size: 16),
                      const SizedBox(width: AppSizes.xs),
                      const Text('Instructor: H. R. Verma'),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: AppSizes.xs),
                      Text(timings[index]),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(90, 36),
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                        ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Batch'),
      ),
    );
  }
}
