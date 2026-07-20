import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/logout_confirmation_dialog.dart';
import '../../../../core/services/update_checker.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUploading = false;

  Future<void> _changeAvatar(UserProfile profile) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      // Limit to 1MB (1,048,576 bytes)
      if (file.size > 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size must be less than 1MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final client = Supabase.instance.client;
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final Uint8List fileBytes = file.bytes ?? 
          (file.path != null && file.path!.isNotEmpty ? await File(file.path!).readAsBytes() : Uint8List(0));

      if (fileBytes.isEmpty) {
        throw Exception('Could not read image file bytes');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = '${user.id}/$timestamp-$sanitizedName';

      await client.storage.from('avatars').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'image/png',
          upsert: true,
        ),
      );

      final avatarUrl = client.storage.from('avatars').getPublicUrl(storagePath);
      await ref.read(authRepositoryProvider).updateAvatarUrl(avatarUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        GestureDetector(
                          onTap: _isUploading ? null : () => _changeAvatar(profile),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: colors.primary.withValues(alpha: 0.1),
                                backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                    ? NetworkImage(profile.avatarUrl!)
                                    : null,
                                child: _isUploading
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      )
                                    : (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                        ? null
                                        : Text(
                                            profile.name.isNotEmpty
                                                ? profile.name.substring(0, 1).toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              color: colors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28,
                                            ),
                                          )),
                              ),
                              if (!_isUploading)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.camera,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
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
                  Divider(height: 1, color: colors.outline.withValues(alpha: 0.08)),
                  ListTile(
                    leading: Icon(LucideIcons.bellRing, color: colors.primary),
                    title: const Text('Notification Preferences'),
                    subtitle: Text(
                      'Manage alerts for homework, fees, results, etc.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                    onTap: () {
                      context.go('/settings/notifications');
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
            const SizedBox(height: 24),

            // ── App Info ──
            Text(
              'App Info',
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
                    leading: Icon(LucideIcons.info, color: colors.onSurfaceVariant),
                    title: const Text('Version'),
                    trailing: Text(
                      UpdateChecker.currentVersion,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.outline.withValues(alpha: 0.08)),
                  ListTile(
                    leading: Icon(LucideIcons.refreshCw, color: colors.onSurfaceVariant),
                    title: const Text('Check for Updates'),
                    subtitle: Text(
                      'Search for newer builds on GitHub',
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                    onTap: () {
                      UpdateChecker.checkForUpdates(context, showNoUpdateToast: true);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Developer Footer Section
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          'https://github.com/arpit0381.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 28,
                            height: 28,
                            color: colors.primary.withValues(alpha: 0.1),
                            child: Icon(LucideIcons.user, size: 16, color: colors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Developed by Arpit Bajpai',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(LucideIcons.externalLink, size: 16, color: colors.primary),
                        onPressed: () async {
                          final uri = Uri.parse('https://arpitbajpai.in');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'arpitbajpai.in',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
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
