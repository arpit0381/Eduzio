import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../../shared/widgets/logout_confirmation_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeControllerProvider);
    final userAsync = ref.watch(authStateProvider);

    final horizontalPadding = getValueForScreenType<double>(
      context: context,
      mobile: 16,
      tablet: 24,
      desktop: 24,
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -1.0,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // ── User Profile Card ──
            userAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name.substring(0, 1).toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile.email,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  profile.role.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, s) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // ── App Preferences ──
            Text(
              'App Preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      isDark ? LucideIcons.moon : LucideIcons.sun,
                      color: colors.primary,
                    ),
                    title: const Text('Dark Theme'),
                    subtitle: Text(
                      isDark ? 'Night mode is on' : 'Switch to dark mode',
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (val) {
                      ref.read(themeControllerProvider.notifier).toggle();
                    },
                  ),
                  Divider(height: 1, color: colors.outline.withValues(alpha: 0.08)),
                  SwitchListTile(
                    secondary: Icon(LucideIcons.bell, color: colors.primary),
                    title: const Text('Push Notifications'),
                    subtitle: Text(
                      'Receive alerts for homework & fees',
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    value: ref.watch(notificationsEnabledProvider),
                    onChanged: (val) {
                      ref.read(notificationsEnabledProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Institute Configuration ──
            if (userAsync.value != null && userAsync.value!.role != UserProfileRole.student) ...[
              Text(
                'Institute Configuration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(LucideIcons.building2, color: colors.onSurfaceVariant),
                      title: const Text('Institute Profile'),
                      subtitle: Text(
                        'Name, logo, contact details',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Icon(LucideIcons.chevronRight, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                      onTap: () {},
                    ),
                    Divider(height: 1, color: colors.outline.withValues(alpha: 0.08)),
                    ListTile(
                      leading: Icon(LucideIcons.creditCard, color: colors.onSurfaceVariant),
                      title: const Text('ID Card Template'),
                      subtitle: Text(
                        'Customize printable student ID',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Icon(LucideIcons.chevronRight, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Security ──
            Text(
              'Security',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(LucideIcons.lock, color: colors.onSurfaceVariant),
                    title: const Text('Change Password'),
                    trailing: Icon(LucideIcons.chevronRight, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: colors.outline.withValues(alpha: 0.08)),
                  ListTile(
                    leading: Icon(LucideIcons.logOut, color: colors.error),
                    title: Text('Sign Out', style: TextStyle(color: colors.error, fontWeight: FontWeight.w600)),
                    onTap: () {
                      showLogoutConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
