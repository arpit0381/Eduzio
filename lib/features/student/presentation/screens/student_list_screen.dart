import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/sizes.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/student_detail.dart';
import '../../domain/entities/student_guardian.dart';
import '../controllers/student_controller.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  void _showAddStudentDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final guardianNameController = TextEditingController();
    final relationController = TextEditingController(text: 'Father');

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Add New Student'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Student Full Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Student Email'),
                    validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Student Phone'),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Guardian Section
                  const Row(
                    children: [
                      Icon(Icons.family_restroom, size: 20),
                      SizedBox(width: AppSizes.sm),
                      Text('Guardian Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  TextFormField(
                    controller: guardianNameController,
                    decoration: const InputDecoration(labelText: 'Guardian Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Enter guardian name' : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: relationController,
                    decoration: const InputDecoration(labelText: 'Relation (e.g. Father, Mother)'),
                  ),
                ],
              ),
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
                  final studentDetail = StudentDetail(
                    profile: UserProfile(
                      id: '',
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                      role: UserProfileRole.student,
                    ),
                    guardian: StudentGuardian(
                      studentId: '',
                      guardianName: guardianNameController.text.trim(),
                      relation: relationController.text.trim().isNotEmpty ? relationController.text.trim() : 'Father',
                    ),
                  );

                  try {
                    await ref.read(studentsListProvider.notifier).addStudent(
                          studentDetail,
                          passwordController.text,
                        );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add student: $e'), backgroundColor: colors.error),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showCsvImportDialog(BuildContext context, WidgetRef ref) {
    final csvController = TextEditingController();
    final passwordController = TextEditingController(text: 'Welcome@123');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Bulk Import Students (CSV)'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CSV Header format:\nName, Email, Phone, Guardian Name, Relation',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: csvController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'CSV Rows',
                      hintText: 'John Doe,john@eduzio.com,+919876543210,Bob Doe,Father',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Paste CSV content' : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Default Accounts Password'),
                    validator: (v) => v == null || v.isEmpty ? 'Enter default password' : null,
                  ),
                ],
              ),
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
                  try {
                    final count = await ref.read(studentsListProvider.notifier).importStudents(
                          csvController.text,
                          passwordController.text,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully imported $count students!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Import failed: $e'), backgroundColor: colors.error),
                      );
                    }
                  }
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StudentDetail student) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete student "${student.profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
            onPressed: () async {
              try {
                await ref.read(studentsListProvider.notifier).deleteStudent(student.profile.id);
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
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import CSV',
            onPressed: () => _showCsvImportDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentsListProvider),
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: colors.outline.withOpacity(0.5)),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'No Students Registered',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    const Text('Click the "+" button below to add your first student.'),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      student.profile.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join(),
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student.profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Email: ${student.profile.email}'),
                      if (student.guardian != null)
                        Text('Guardian: ${student.guardian!.guardianName} (${student.guardian!.relation})'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(context, ref, student);
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
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: AppSizes.sm),
                            Text('Delete Student', style: TextStyle(color: Colors.red)),
                          ],
                        ),
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
                Text('Error loading students: $err', textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.md),
                ElevatedButton(
                  onPressed: () => ref.invalidate(studentsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
    );
  }
}
