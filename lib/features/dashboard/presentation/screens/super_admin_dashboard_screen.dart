import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/dashboard_controller.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    int crossAxisCount = 1;
    if (size.width > 1200) {
      crossAxisCount = 3;
    } else if (size.width > 600) {
      crossAxisCount = 2;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apple Health style dynamic greeting header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System Overview',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                  ),
                  child: Icon(LucideIcons.settings, color: colors.onSurface, size: 20),
                ),
              ],
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            // Intro Card
            Card(
              color: colors.primary.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(LucideIcons.shieldCheck, color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Super Admin Control',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have access to monitor and manage all registered organizations across the Eduzio network.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fade(delay: 50.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            ref.watch(superAdminDashboardStatsProvider).when(
              data: (stats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Stats',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: [
                        _buildMetricCard(context, 'Total Institutes', '${stats.totalInstitutes}', LucideIcons.building, Colors.blue),
                        _buildMetricCard(context, 'Total Users', '${stats.totalUsers}', LucideIcons.users, Colors.teal),
                      ],
                    ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),

                    Text(
                      'Recent Institutes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: stats.recentInstitutes.isEmpty
                          ? _buildEmptyState(context, 'No registered institutes found.')
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: stats.recentInstitutes.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: colors.outline.withValues(alpha: 0.05)),
                              itemBuilder: (context, index) {
                                final org = stats.recentInstitutes[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(LucideIcons.building, color: colors.primary, size: 20),
                                  ),
                                  title: Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(org.subdomain, style: GoogleFonts.inter()),
                                  trailing: Icon(LucideIcons.chevronRight, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                                  onTap: () {
                                    if (context.mounted) context.push('/institutes/${org.id}');
                                  },
                                );
                              },
                            ),
                    ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: colors.error))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                textStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.building, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
