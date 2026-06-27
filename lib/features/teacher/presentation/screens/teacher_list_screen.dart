import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class TeacherListScreen extends StatelessWidget {
  const TeacherListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: 3,
        itemBuilder: (context, index) {
          final names = ['Dr. H. R. Verma', 'Mrs. Shalini Gupta', 'Mr. Amit Deshmukh'];
          final subjects = ['Physics & Mechanics', 'Organic Chemistry', 'Calculus & Algebra'];
          final phones = ['+91 98765 43210', '+91 87654 32109', '+91 76543 21098'];
          final emails = ['hr.verma@eduzio.com', 's.gupta@eduzio.com', 'a.deshmukh@eduzio.com'];
          final batchCounts = [4, 3, 5];

          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colors.secondaryContainer,
                        child: Icon(Icons.person, color: colors.onSecondaryContainer),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              names[index],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              subjects[index],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          '${batchCounts[index]} Batches',
                          style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16),
                      const SizedBox(width: AppSizes.xs),
                      Text(phones[index]),
                      const SizedBox(width: AppSizes.lg),
                      const Icon(Icons.email_outlined, size: 16),
                      const SizedBox(width: AppSizes.xs),
                      Text(emails[index]),
                    ],
                  ),
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
                        child: const Text('View Batches'),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                        ),
                        child: const Text('Edit Profile'),
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
        label: const Text('Add Teacher'),
      ),
    );
  }
}
