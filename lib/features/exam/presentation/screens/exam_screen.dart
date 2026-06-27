import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests & Exams'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: 2,
        itemBuilder: (context, index) {
          final titles = ['Electrostatics Unit Test 1', 'Periodic Classification Quiz'];
          final subjects = ['Physics', 'Chemistry'];
          final batches = ['Class 12 - Physics', 'Class 12 - Chemistry'];
          final dates = ['June 20, 2026', 'June 18, 2026'];
          final maxMarks = ['50', '30'];
          final status = ['Marks Entered', 'Pending Marks'];

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
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          subjects[index],
                          style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: status[index] == 'Marks Entered' ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(
                            color: status[index] == 'Marks Entered' ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Text(
                          status[index],
                          style: TextStyle(
                            color: status[index] == 'Marks Entered' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    titles[index],
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text('Batch: ${batches[index]} | Date: ${dates[index]}'),
                  Text('Maximum Marks: ${maxMarks[index]}'),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                        ),
                        child: const Text('View Ranklist'),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                        ),
                        child: Text(status[index] == 'Marks Entered' ? 'Edit Marks' : 'Enter Marks'),
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
        label: const Text('Create Test'),
      ),
    );
  }
}
