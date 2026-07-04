import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String path;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
  });
}

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  List<_NavItem> _getNavItems(UserProfileRole role) {
    if (role == UserProfileRole.superAdmin) {
      return [
        const _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, path: '/dashboard'),
        const _NavItem(label: 'Institutes', icon: LucideIcons.building, path: '/institutes'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, path: '/settings'),
      ];
    } else if (role == UserProfileRole.student) {
      return [
        const _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, path: '/dashboard'),
        const _NavItem(label: 'Homework', icon: LucideIcons.bookOpen, path: '/homework'),
        const _NavItem(label: 'Attendance', icon: LucideIcons.clipboardCheck, path: '/attendance'),
        const _NavItem(label: 'Fees', icon: LucideIcons.creditCard, path: '/fees'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, path: '/settings'),
      ];
    } else {
      // Admin / Teacher
      return [
        const _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, path: '/dashboard'),
        const _NavItem(label: 'Batches', icon: LucideIcons.grid, path: '/batches'),
        const _NavItem(label: 'Students', icon: LucideIcons.users, path: '/students'),
        const _NavItem(label: 'Teachers', icon: LucideIcons.graduationCap, path: '/teachers'),
        const _NavItem(label: 'Attendance', icon: LucideIcons.clipboardCheck, path: '/attendance'),
        const _NavItem(label: 'Homework', icon: LucideIcons.bookOpen, path: '/homework'),
        const _NavItem(label: 'Exams', icon: LucideIcons.fileText, path: '/exams'),
        const _NavItem(label: 'Fees', icon: LucideIcons.creditCard, path: '/fees'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, path: '/settings'),
      ];
    }
  }

  int _getSelectedIndex(BuildContext context, List<_NavItem> items) {
    final String location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path) && items[i].path != '/') {
        return i;
      }
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, List<_NavItem> items) {
    if (index >= 0 && index < items.length) {
      final path = items[index].path;
      Future.microtask(() {
        if (context.mounted) {
          context.go(path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(authStateProvider);
    final role = userProfileAsync.value?.role ?? UserProfileRole.student;
    
    final navItems = _getNavItems(role);
    final selectedIndex = _getSelectedIndex(context, navItems);

    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure it's transparent here too
      extendBody: true, // Allows content to scroll behind the floating bottom bar
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.pastelBackgroundGradient,
        ),
        child: ResponsiveLayout(
          // Mobile Layout: Floating iOS-style Bottom Bar
        mobile: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 90), // Prevent content cutoff
                child: child,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildFloatingBottomBar(context, navItems, selectedIndex),
            ),
          ],
        ),

        // Tablet Layout: Sleek Side Rail
        tablet: Row(
          children: [
            _buildTabletNavigationRail(context, navItems, selectedIndex),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Expanded(child: child),
          ],
        ),

        // Desktop Layout: Permanent Stripe-style Sidebar
        desktop: Row(
          children: [
            _buildDesktopSidebar(context, ref, navItems, selectedIndex, userProfileAsync),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Expanded(child: child),
          ],
        ),
      ),
      ),
    );
  }

  // Floating iOS glass bottom bar
  Widget _buildFloatingBottomBar(BuildContext context, List<_NavItem> items, int selectedIndex) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final displayItems = items.take(5).toList(); // Show max 5 items on mobile

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusXxl), // 32px
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(displayItems.length, (index) {
              final item = displayItems[index];
              final isSelected = selectedIndex == index;
              return GestureDetector(
                onTap: () => _onItemTapped(index, context, items),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Tablet Side Rail
  Widget _buildTabletNavigationRail(BuildContext context, List<_NavItem> items, int selectedIndex) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: 80,
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(LucideIcons.graduationCap, color: colors.primary, size: 28),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Tooltip(
                    message: item.label,
                    child: InkWell(
                      onTap: () => _onItemTapped(index, context, items),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected ? colors.primary : colors.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Stripe Dashboard style Persistent Desktop Sidebar
  Widget _buildDesktopSidebar(
    BuildContext context,
    WidgetRef ref,
    List<_NavItem> items,
    int selectedIndex,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: AppSizes.navDrawerWidth,
      color: isDark ? const Color(0xFF151B2E) : Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header Branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.graduationCap, color: colors.primary, size: 24),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                'Eduzio',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Sidebar Navigation List
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => _onItemTapped(index, context, items),
                    borderRadius: BorderRadius.circular(18), // Apple-like
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Section (Apple-like floating panel inside sidebar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Icon(LucideIcons.user, color: colors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: userProfileAsync.when(
                    data: (profile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.name ?? 'Anonymous',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            profile?.email ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                    loading: () => const Text('Loading...'),
                    error: (err, stack) => const Text('Error'),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(LucideIcons.logOut, color: colors.error, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
