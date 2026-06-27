import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/sizes.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../controllers/teacher_controller.dart';

class TeacherListScreen extends ConsumerWidget {
  const TeacherListScreen({super.key});

  void _showAddTeacherDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Add New Teacher'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Teacher Full Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Teacher Email'),
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
                    decoration: const InputDecoration(
                      labelText: 'Teacher Phone',
                      hintText: 'e.g. +91 9876543210',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
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
                  final teacher = UserProfile(
                    id: '',
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    role: UserProfileRole.teacher,
                  );

                  try {
                    await ref.read(teachersListProvider.notifier).addTeacher(
                          teacher,
                          passwordController.text,
                        );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add teacher: $e'), backgroundColor: colors.error),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, UserProfile teacher) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete teacher "${teacher.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
            onPressed: () async {
              try {
                await ref.read(teachersListProvider.notifier).deleteTeacher(teacher.id);
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
    final teachersAsync = ref.watch(teachersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teachersListProvider),
          ),
        ],
      ),
      body: teachersAsync.when(
        data: (teachers) {
          if (teachers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: colors.outline.withOpacity(0.5)),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'No Teachers Registered',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    const Text('Click the "+" button below to add your first teacher.'),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];

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
                            child: Text(
                              teacher.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join(),
                              style: TextStyle(color: colors.onSecondaryContainer, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacher.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  teacher.email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16),
                          const SizedBox(width: AppSizes.xs),
                          Text(teacher.phone ?? 'No Phone Number'),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: colors.error),
                            tooltip: 'Delete Teacher',
                            onPressed: () => _confirmDelete(context, ref, teacher),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 36),
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                            ),
                            child: const Text('View Batches'),
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
                Text('Error loading teachers: $err', textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.md),
                ElevatedButton(
                  onPressed: () => ref.invalidate(teachersListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeacherDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
      ),
    );
  }
}
