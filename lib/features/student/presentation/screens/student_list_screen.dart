import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import CSV',
            onPressed: () {},
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: 5,
        itemBuilder: (context, index) {
          final names = ['Aarav Sharma', 'Ananya Patel', 'Kabir Singh', 'Diya Sen', 'Rohan Gupta'];
          final rollNos = ['EDZ2026001', 'EDZ2026002', 'EDZ2026003', 'EDZ2026004', 'EDZ2026005'];
          final batches = ['Class 12 - Physics', 'Class 12 - Chemistry', 'Class 12 - Physics', 'IIT-JEE Crash Course', 'Class 11 - Mathematics'];
          final parentNames = ['Rajesh Sharma', 'Suresh Patel', 'Jaspreet Singh', 'Amit Sen', 'Sunil Gupta'];

          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.md),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
              leading: CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Text(
                  names[index].split(' ').map((e) => e[0]).join(),
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Roll No: ${rollNos[index]} | Batch: ${batches[index]}'),
                  Text('Guardian: ${parentNames[index]}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'id_card') {
                    // Generate ID Card
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: AppSizes.sm),
                        Text('View Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'id_card',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_outlined, size: 20),
                        SizedBox(width: AppSizes.sm),
                        Text('Generate ID Card'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: AppSizes.sm),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: colors.error),
                        const SizedBox(width: AppSizes.sm),
                        Text('Delete', style: TextStyle(color: colors.error)),
                      ],
                    ),
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
        label: const Text('Add Student'),
      ),
    );
  }
}
