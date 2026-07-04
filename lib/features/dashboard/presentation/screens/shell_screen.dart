import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/sizes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../controllers/dashboard_controller.dart';

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
        const _NavItem(label: 'Users', icon: LucideIcons.users, path: '/users'),
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

  // Top bar items for mobile (shown in the top app bar area)
  List<_NavItem> _getMobileTopItems(UserProfileRole role) {
    if (role == UserProfileRole.superAdmin) {
      return [];
    } else if (role == UserProfileRole.student) {
      return [];
    } else {
      // Admin/Teacher: Attendance, Homework, Exams, Fees go to top action bar
      return [
        const _NavItem(label: 'Attendance', icon: LucideIcons.clipboardCheck, path: '/attendance'),
        const _NavItem(label: 'Homework', icon: LucideIcons.bookOpen, path: '/homework'),
        const _NavItem(label: 'Exams', icon: LucideIcons.fileText, path: '/exams'),
        const _NavItem(label: 'Fees', icon: LucideIcons.creditCard, path: '/fees'),
      ];
    }
  }

  // Bottom bar items for mobile
  List<_NavItem> _getMobileBottomItems(UserProfileRole role) {
    if (role == UserProfileRole.superAdmin) {
      return [
        const _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, path: '/dashboard'),
        const _NavItem(label: 'Institutes', icon: LucideIcons.building, path: '/institutes'),
        const _NavItem(label: 'Users', icon: LucideIcons.users, path: '/users'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, path: '/settings'),
      ];
    } else if (role == UserProfileRole.student) {
      return [
        const _NavItem(label: 'Home', icon: LucideIcons.layoutDashboard, path: '/dashboard'),
        const _NavItem(label: 'Homework', icon: LucideIcons.bookOpen, path: '/homework'),
        const _NavItem(label: 'Attendance', icon: LucideIcons.clipboardCheck, path: '/attendance'),
        const _NavItem(label: 'Fees', icon: LucideIcons.creditCard, path: '/fees'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, path: '/settings'),
      ];
    } else {
      // Admin/Teacher: Bottom = Dashboard, Batches, Students, Teachers, Settings
      return [
        const _NavItem(label: 'Home', icon: LucideIcons.layoutDashboard, path: '/dashboard'),
        const _NavItem(label: 'Batches', icon: LucideIcons.grid, path: '/batches'),
        const _NavItem(label: 'Students', icon: LucideIcons.users, path: '/students'),
        const _NavItem(label: 'Teachers', icon: LucideIcons.graduationCap, path: '/teachers'),
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

  int _getSelectedBottomIndex(BuildContext context, List<_NavItem> bottomItems) {
    final String location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < bottomItems.length; i++) {
      if (location.startsWith(bottomItems[i].path) && bottomItems[i].path != '/') {
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
    
    final orgId = userProfileAsync.value?.organizationId;
    final orgDetailsAsync = orgId != null ? ref.watch(instituteDetailsProvider(orgId)) : null;

    final navItems = _getNavItems(role);
    final selectedIndex = _getSelectedIndex(context, navItems);

    final isMobile = getValueForScreenType<bool>(
      context: context,
      mobile: true,
      tablet: false,
      desktop: false,
    );

    if (isMobile) {
      return _buildMobileLayout(context, ref, role, userProfileAsync, orgDetailsAsync);
    }

    final isTablet = getValueForScreenType<bool>(
      context: context,
      mobile: false,
      tablet: true,
      desktop: false,
    );

    return Scaffold(
      body: Row(
        children: [
          if (isTablet)
            _buildTabletNavigationRail(context, navItems, selectedIndex),
          if (!isTablet)
            _buildDesktopSidebar(context, ref, navItems, selectedIndex, userProfileAsync, orgDetailsAsync),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ── MOBILE LAYOUT ──────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, UserProfileRole role, AsyncValue<UserProfile?> userProfileAsync, AsyncValue<InstituteDetails>? orgDetailsAsync) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bottomItems = _getMobileBottomItems(role);
    final topItems = _getMobileTopItems(role);
    final selectedBottomIndex = _getSelectedBottomIndex(context, bottomItems);

    return Scaffold(
      body: Column(
        children: [
          // ── TOP: Custom App Bar with logo + action icons ──
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Column(
                children: [
                  // Row 1: Logo + Profile/Logout
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.graduationCap, color: colors.primary, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eduzio',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: colors.primary,
                            ),
                          ),
                          if (orgDetailsAsync != null)
                            orgDetailsAsync.when(
                              data: (org) => Text(
                                org.name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (e, s) => const SizedBox.shrink(),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Profile avatar
                      userProfileAsync.when(
                        data: (profile) => GestureDetector(
                          onTap: () => context.go('/settings'),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.primary.withValues(alpha: 0.1),
                            child: Text(
                              (profile?.name ?? 'U').substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        loading: () => const SizedBox(width: 32, height: 32),
                        error: (e, s) => const SizedBox(width: 32, height: 32),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(LucideIcons.logOut, color: colors.error, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).signOut();
                        },
                      ),
                    ],
                  ),

                  // Row 2: Top action icon chips (only for admin/teacher)
                  if (topItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: topItems.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = topItems[index];
                          final String location = GoRouterState.of(context).matchedLocation;
                          final isActive = location.startsWith(item.path);
                          return GestureDetector(
                            onTap: () => context.go(item.path),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? colors.primary.withValues(alpha: 0.1)
                                    : (isDark ? colors.surface : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(100),
                                border: isActive
                                    ? Border.all(color: colors.primary.withValues(alpha: 0.3))
                                    : Border.all(color: colors.outline.withValues(alpha: 0.08)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 16,
                                    color: isActive ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      color: isActive ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.outline.withValues(alpha: 0.08)),

          // ── BODY ──
          Expanded(child: child),
        ],
      ),

      // ── BOTTOM NAVIGATION BAR ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151B2E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: colors.outline.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(bottomItems.length, (index) {
                final item = bottomItems[index];
                final isSelected = selectedBottomIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index, context, bottomItems),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant.withValues(alpha: 0.5),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── TABLET SIDE RAIL ───────────────────────────────────────────────────
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
                      borderRadius: BorderRadius.circular(100),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
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

  // ── DESKTOP SIDEBAR ────────────────────────────────────────────────────
  Widget _buildDesktopSidebar(
    BuildContext context,
    WidgetRef ref,
    List<_NavItem> items,
    int selectedIndex,
    AsyncValue<UserProfile?> userProfileAsync,
    AsyncValue<InstituteDetails>? orgDetailsAsync,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eduzio',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: colors.onSurface,
                    ),
                  ),
                  if (orgDetailsAsync != null)
                    orgDetailsAsync.when(
                      data: (org) => Text(
                        org.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                ],
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
                    borderRadius: BorderRadius.circular(100),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
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

          // User Section
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
