import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
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
    
    final crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );

    final cardAspectRatio = getValueForScreenType<double>(
      context: context,
      mobile: 2.2,
      tablet: 1.6,
      desktop: 1.6,
    );

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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    _instituteCode!,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                      childAspectRatio: cardAspectRatio,
                      children: [
                        _buildMetricCard(context, 'Total Students', '${stats.totalStudents}', LucideIcons.users, const Color(0xFFC4B5FD), '+10% This Month'),
                        _buildMetricCard(context, 'Active Batches', '${stats.activeBatches}', LucideIcons.layoutGrid, const Color(0xFFBAE6FD), '+5 This Month'),
                        _buildMetricCard(context, 'Attendance', '${stats.attendancePercentage.toStringAsFixed(1)}%', LucideIcons.checkCircle2, const Color(0xFFbbf7d0), '+2% This Month'),
                        _buildMetricCard(context, 'Fees Collected', '₹${stats.feesCollected.toStringAsFixed(0)}', LucideIcons.wallet, const Color(0xFFfed7aa), '+15% This Month'),
                      ],
                    ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),

                    // Main dynamic columns (Schedule + Actions)
                    Builder(
                      builder: (context) {
                        final isDesktop = getValueForScreenType<bool>(
                          context: context,
                          mobile: false,
                          tablet: false,
                          desktop: true,
                        );
                        
                        return Flex(
                          direction: isDesktop ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Active Batches)
                            isDesktop 
                              ? Expanded(
                                  flex: 2,
                                  child: _buildLeftColumn(theme, stats, colors, context),
                                )
                              : _buildLeftColumn(theme, stats, colors, context),
                          
                          // Right Column (Quick Actions)
                          if (!isDesktop) const SizedBox(height: 32),
                          if (isDesktop) const SizedBox(width: 24),
                          
                          isDesktop
                            ? Expanded(
                                flex: 1,
                                child: _buildRightColumn(theme, colors, context),
                              )
                            : _buildRightColumn(theme, colors, context),
                          ],
                        );
                      }
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

  Widget _buildLeftColumn(ThemeData theme, dynamic stats, ColorScheme colors, BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildRightColumn(ThemeData theme, ColorScheme colors, BuildContext context) {
    return Column(
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
                _buildActionButton(context, 'Take Attendance', LucideIcons.clipboardCheck, colors.primary, () => context.go('/attendance/take')),
                const SizedBox(height: 12),
                _buildActionButton(context, 'Add New Student', LucideIcons.userPlus, colors.secondary, () => context.go('/students')),
                const SizedBox(height: 12),
                _buildActionButton(context, 'Create Homework', LucideIcons.plusCircle, Colors.blueGrey, () => context.go('/homework')),
                const SizedBox(height: 12),
                _buildActionButton(context, 'View Reports', LucideIcons.barChart3, Colors.orange, () => context.go('/attendance/reports')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accentColor,
    String badgeText,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.15 : 0.4),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background Icon Watermark
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 100,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      textStyle: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                // Pill tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.trendingUp, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
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
