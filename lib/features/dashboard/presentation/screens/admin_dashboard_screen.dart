import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String? _instituteCode;

  @override
  void initState() {
    super.initState();
    _fetchInstituteCode();
  }

  Future<void> _fetchInstituteCode() async {
    final user = ref.read(authStateProvider).value;
    if (user?.organizationId != null) {
      try {
        final data = await Supabase.instance.client
            .from('organizations')
            .select('subdomain')
            .eq('id', user!.organizationId!)
            .single();
        if (mounted) {
          setState(() {
            _instituteCode = data['subdomain'] as String?;
          });
        }
      } catch (e) {
        debugPrint('Failed to fetch institute code: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    int crossAxisCount = 1;
    if (size.width > 1200) {
      crossAxisCount = 4;
    } else if (size.width > 800) {
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
                      'Institution Analytics',
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
                  child: Icon(LucideIcons.bell, color: colors.onSurface, size: 20),
                ),
              ],
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            // Share Institute Code Card
            if (_instituteCode != null) ...[
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
                        child: Icon(LucideIcons.key, color: colors.primary, size: 22),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Institute Code',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Instructors and students can enter this code during signup to instantly join.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Copy pill button
                      Material(
                        color: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _instituteCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied code to clipboard')),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  _instituteCode!,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(LucideIcons.copy, color: colors.primary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 50.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
            ],

            ref.watch(adminDashboardStatsProvider).when(
              data: (stats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid statistics
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      children: [
                        _buildMetricCard(context, 'Total Students', '${stats.totalStudents}', LucideIcons.users, Colors.blue),
                        _buildMetricCard(context, 'Active Batches', '${stats.activeBatches}', LucideIcons.grid, Colors.teal),
                        _buildMetricCard(context, 'Attendance', '${stats.attendancePercentage.toStringAsFixed(1)}%', LucideIcons.checkCircle2, Colors.green),
                        _buildMetricCard(context, 'Fees Collected', '₹${stats.feesCollected.toStringAsFixed(0)}', LucideIcons.creditCard, Colors.orange),
                      ],
                    ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),

                    // Main dynamic columns (Schedule + Actions)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Active Batches)
                        Expanded(
                          flex: size.width > 900 ? 2 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Batches',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: stats.recentBatches.isEmpty
                                    ? _buildEmptyState(context, 'No active batches found.')
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: stats.recentBatches.length,
                                        separatorBuilder: (_, index) => Divider(height: 1, color: colors.outline.withValues(alpha: 0.05)),
                                        itemBuilder: (context, index) {
                                          final batch = stats.recentBatches[index];
                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                            leading: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: colors.primary.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Icon(LucideIcons.bookOpen, color: colors.primary, size: 20),
                                            ),
                                            title: Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text('Code: ${batch.code}', style: GoogleFonts.inter()),
                                            trailing: Icon(LucideIcons.chevronRight, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                                            onTap: () {},
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),

                        // Right Column (Quick Actions)
                        if (size.width > 900) ...[
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Actions',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildActionButton(context, 'Take Attendance', LucideIcons.clipboardCheck, colors.primary),
                                        const SizedBox(height: 12),
                                        _buildActionButton(context, 'Add New Student', LucideIcons.userPlus, colors.secondary),
                                        const SizedBox(height: 12),
                                        _buildActionButton(context, 'Create Homework', LucideIcons.plusCircle, Colors.blueGrey),
                                        const SizedBox(height: 12),
                                        _buildActionButton(context, 'View Reports', LucideIcons.barChart3, Colors.orange),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
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
            Icon(LucideIcons.grid, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
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
