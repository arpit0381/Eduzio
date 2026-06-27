import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework & Assignments'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: 3,
        itemBuilder: (context, index) {
          final titles = ['Electrostatics Problem Set 1', 'Periodic Table Notes & Exercise', 'Matrix Multiplication Assignment'];
          final subjects = ['Physics', 'Chemistry', 'Mathematics'];
          final batches = ['Class 12 - Physics', 'Class 12 - Chemistry', 'Class 11 - Mathematics'];
          final dueDates = ['July 02, 2026', 'June 30, 2026', 'July 05, 2026'];
          final submissions = ['38/45', '41/42', '12/38'];

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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          subjects[index],
                          style: TextStyle(color: colors.onSecondaryContainer, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Text(
                        'Due: ${dueDates[index]}',
                        style: TextStyle(color: colors.error, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    titles[index],
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Batch: ${batches[index]}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 18),
                          const SizedBox(width: AppSizes.xs),
                          Text('Submissions: ${submissions[index]}'),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(90, 36),
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                            ),
                            child: const Text('Submissions'),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(90, 36),
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                            ),
                            child: const Text('View PDF'),
                          ),
                        ],
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
        label: const Text('Add Homework'),
      ),
    );
  }
}
