import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/notification_controller.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          Text(
            'Control which categories of notifications you want to receive on your device.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          _buildPreferenceTile(
            context,
            ref,
            title: 'Homework & Assignments',
            description: 'Get notified when new homework is assigned or updated.',
            icon: LucideIcons.bookOpen,
            value: prefs.homework,
            category: 'homework',
          ),
          const Divider(height: 1),

          _buildPreferenceTile(
            context,
            ref,
            title: 'Attendance Updates',
            description: 'Get notified when your attendance register is marked.',
            icon: LucideIcons.calendarCheck2,
            value: prefs.attendance,
            category: 'attendance',
          ),
          const Divider(height: 1),

          _buildPreferenceTile(
            context,
            ref,
            title: 'Fee Invoices & Payments',
            description: 'Get notified of outstanding invoices or receipts.',
            icon: LucideIcons.wallet,
            value: prefs.fees,
            category: 'fees',
          ),
          const Divider(height: 1),

          _buildPreferenceTile(
            context,
            ref,
            title: 'Exam Results & Grades',
            description: 'Get notified when grades are published.',
            icon: LucideIcons.award,
            value: prefs.results,
            category: 'results',
          ),
          const Divider(height: 1),

          _buildPreferenceTile(
            context,
            ref,
            title: 'Institute Events',
            description: 'Get notified of upcoming events and functions.',
            icon: LucideIcons.partyPopper,
            value: prefs.events,
            category: 'events',
          ),
          const Divider(height: 1),

          _buildPreferenceTile(
            context,
            ref,
            title: 'Official Announcements',
            description: 'Get critical announcements published by administrators.',
            icon: LucideIcons.megaphone,
            value: prefs.announcements,
            category: 'announcements',
          ),
          const Divider(height: 1),

          _buildPreferenceTile(
            context,
            ref,
            title: 'Marketing & Offers',
            description: 'Receive newsletters, course promotions, and updates.',
            icon: LucideIcons.badgePercent,
            value: prefs.marketing,
            category: 'marketing',
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required String category,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        value: value,
        onChanged: (val) {
          ref.read(notificationPreferencesProvider.notifier).updatePreference(category, val);
        },
      ),
    );
  }
}
