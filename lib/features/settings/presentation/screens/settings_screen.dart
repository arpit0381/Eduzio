import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _emailReports = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // Institute Profile Section
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
                  leading: const Icon(Icons.business),
                  title: const Text('Institute Profile'),
                  subtitle: const Text('Name, logo, contact, and slug details'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('ID Card Template'),
                  subtitle: const Text('Customize printable student ID styling'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // User Preferences Section
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
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Toggle night mode styling'),
                  value: _darkMode,
                  onChanged: (val) => setState(() => _darkMode = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive notifications for homework & fees'),
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.mail_outline),
                  title: const Text('Daily Summary Emails'),
                  subtitle: const Text('Receive reports on daily collections & attendance'),
                  value: _emailReports,
                  onChanged: (val) => setState(() => _emailReports = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Account Security Section
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
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: colors.error),
                  title: Text('Delete Institute Account', style: TextStyle(color: colors.error)),
                  subtitle: const Text('Irreversibly remove all organization data'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
