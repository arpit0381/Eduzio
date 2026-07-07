import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../controllers/dashboard_controller.dart';

class SuperAdminUsersScreen extends ConsumerWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final usersAsync = ref.watch(superAdminUsersProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'All Platform Users',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: -1),
            ),
            centerTitle: false,
            pinned: true,
          ),
          usersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error loading users: $err')),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No users found.')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = users[index];
                      final isSuperAdmin = user['role'] == 'super_admin';
                      final orgData = user['organizations'] as Map<String, dynamic>?;
                      final orgName = isSuperAdmin ? 'Platform Management' : (orgData?['name'] ?? 'Unknown Institute');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                        ),
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isSuperAdmin ? colors.primaryContainer : colors.secondaryContainer,
                            child: Icon(
                              isSuperAdmin ? LucideIcons.shieldAlert : LucideIcons.user,
                              color: isSuperAdmin ? colors.onPrimaryContainer : colors.onSecondaryContainer,
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'No Name',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(user['email'] ?? ''),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(LucideIcons.building, size: 14, color: colors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      orgName,
                                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSuperAdmin ? Colors.red.withValues(alpha: 0.1) : colors.tertiaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (user['role'] as String).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSuperAdmin ? Colors.red : colors.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ).animate().fade(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
                    },
                    childCount: users.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
