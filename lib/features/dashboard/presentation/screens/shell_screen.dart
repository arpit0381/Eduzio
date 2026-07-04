import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

import '../../../auth/domain/entities/user_profile.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  List<_NavItem> _getNavItems(UserProfileRole role) {
    if (role == UserProfileRole.superAdmin) {
      return [
        const _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, path: '/dashboard'),
        const _NavItem(label: 'Institutes', icon: Icons.business_outlined, selectedIcon: Icons.business, path: '/settings'),
        const _NavItem(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings, path: '/settings'),
      ];
    } else if (role == UserProfileRole.student) {
      return [
        const _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, path: '/dashboard'),
        const _NavItem(label: 'Homework', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, path: '/homework'),
        const _NavItem(label: 'Attendance', icon: Icons.fact_check_outlined, selectedIcon: Icons.fact_check, path: '/attendance'),
        const _NavItem(label: 'Fees', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, path: '/fees'),
        const _NavItem(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings, path: '/settings'),
      ];
    } else {
      // Admin / Teacher
      return [
        const _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, path: '/dashboard'),
        const _NavItem(label: 'Batches', icon: Icons.class_outlined, selectedIcon: Icons.class_, path: '/batches'),
        const _NavItem(label: 'Students', icon: Icons.people_outline, selectedIcon: Icons.people, path: '/students'),
        const _NavItem(label: 'Teachers', icon: Icons.school_outlined, selectedIcon: Icons.school, path: '/teachers'),
        const _NavItem(label: 'Attendance', icon: Icons.fact_check_outlined, selectedIcon: Icons.fact_check, path: '/attendance'),
        const _NavItem(label: 'Homework', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, path: '/homework'),
        const _NavItem(label: 'Exams', icon: Icons.quiz_outlined, selectedIcon: Icons.quiz, path: '/exams'),
        const _NavItem(label: 'Fees', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, path: '/fees'),
        const _NavItem(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings, path: '/settings'),
      ];
    }
  }

  // Helper to determine active index based on route path
  int _getSelectedIndex(BuildContext context, List<_NavItem> items) {
    final String location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path) && items[i].path != '/') {
        return i;
      }
    }
    return 0; // default to dashboard
  }

  void _onItemTapped(int index, BuildContext context, List<_NavItem> items) {
    if (index >= 0 && index < items.length) {
      context.go(items[index].path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final userProfileAsync = ref.watch(authStateProvider);
    final role = userProfileAsync.value?.role ?? UserProfileRole.student;
    
    final navItems = _getNavItems(role);
    final selectedIndex = _getSelectedIndex(context, navItems);

    // Sidebar/Drawer navigation items
    final destinations = navItems.map((item) {
      return NavigationDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.selectedIcon),
        label: item.label,
      );
    }).toList();

    return Scaffold(
      body: ResponsiveLayout(
        // Mobile Layout (Bottom Nav Bar)
        mobile: Column(
          children: [
            Expanded(child: child),
            NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: destinations.take(5).toList(), // Limit mobile bottom nav to 5 items
            ),
          ],
        ),

        // Tablet Layout (Side Navigation Rail)
        tablet: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              labelType: NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Icon(Icons.auto_stories, color: colors.primary, size: 28),
              ),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),

        // Desktop Layout (Persistent Navigation Drawer)
        desktop: Row(
          children: [
            Container(
              width: AppSizes.navDrawerWidth,
              color: colors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories, color: colors.primary, size: 32),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          'Eduzio',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Sidebar Items
                  Expanded(
                    child: ListView.builder(
                      itemCount: destinations.length,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm, horizontal: AppSizes.md),
                      itemBuilder: (context, index) {
                        final item = destinations[index];
                        final isSelected = selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            leading: isSelected ? item.selectedIcon : item.icon,
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? colors.primary : colors.onSurfaceVariant,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: colors.primaryContainer.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            ),
                            onTap: () => _onItemTapped(index, context),
                          ),
                        );
                      },
                    ),
                  ),
                  // User Profile Mini Card
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.person, color: colors.primary),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: userProfileAsync.when(
                            data: (profile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?.name ?? 'No Name',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    profile?.email ?? 'No Session',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Text('Loading...'),
                            error: (_, _) => const Text('Error'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () {
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
