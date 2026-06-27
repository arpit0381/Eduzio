import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  // Helper to determine active index based on route path
  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/batches')) return 1;
    if (location.startsWith('/students')) return 2;
    if (location.startsWith('/teachers')) return 3;
    if (location.startsWith('/attendance')) return 4;
    if (location.startsWith('/homework')) return 5;
    if (location.startsWith('/exams')) return 6;
    if (location.startsWith('/fees')) return 7;
    if (location.startsWith('/settings')) return 8;
    return 0; // default to dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/batches');
        break;
      case 2:
        context.go('/students');
        break;
      case 3:
        context.go('/teachers');
        break;
      case 4:
        context.go('/attendance');
        break;
      case 5:
        context.go('/homework');
        break;
      case 6:
        context.go('/exams');
        break;
      case 7:
        context.go('/fees');
        break;
      case 8:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedIndex = _getSelectedIndex(context);
    final userProfileAsync = ref.watch(authStateProvider);

    // Sidebar/Drawer navigation items
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.class_outlined),
        selectedIcon: Icon(Icons.class_),
        label: 'Batches',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Students',
      ),
      const NavigationDestination(
        icon: Icon(Icons.school_outlined),
        selectedIcon: Icon(Icons.school),
        label: 'Teachers',
      ),
      const NavigationDestination(
        icon: Icon(Icons.fact_check_outlined),
        selectedIcon: Icon(Icons.fact_check),
        label: 'Attendance',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Homework',
      ),
      const NavigationDestination(
        icon: Icon(Icons.quiz_outlined),
        selectedIcon: Icon(Icons.quiz),
        label: 'Exams',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Fees',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

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
                            selectedTileColor: colors.primaryContainer.withOpacity(0.4),
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
                            error: (_, __) => const Text('Error'),
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
