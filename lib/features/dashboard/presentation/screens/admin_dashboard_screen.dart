import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/sizes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/services.dart';
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

    // Calculate grid columns dynamically based on screen width
    int crossAxisCount = 1;
    if (size.width > 1200) {
      crossAxisCount = 4;
    } else if (size.width > 600) {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Eduzio!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Here is what is happening at your institute today.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.school, size: 64, color: colors.primary.withValues(alpha: 0.2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            
            // Institute Code Display
            if (_instituteCode != null) ...[
              Card(
                color: colors.secondaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key_outlined, color: colors.secondary),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Institute Code',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Share this code with your students and teachers so they can join your institute.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SelectableText(
                              _instituteCode!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Copy Code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _instituteCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Institute Code copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            ref.watch(adminDashboardStatsProvider).when(
              data: (stats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Section
                    Text(
                      'Quick Stats',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.md),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSizes.md,
                      mainAxisSpacing: AppSizes.md,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(context, 'Total Students', '${stats.totalStudents}', Icons.people, colors.primary),
                        _buildStatCard(context, 'Active Batches', '${stats.activeBatches}', Icons.class_, Colors.teal),
                        _buildStatCard(context, 'Today\'s Attendance', '${stats.attendancePercentage.toStringAsFixed(1)}%', Icons.check_circle, Colors.green),
                        _buildStatCard(context, 'Fees Collected', '₹${stats.feesCollected.toStringAsFixed(0)}', Icons.currency_rupee, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Main Columns (Schedule and Recent Activity)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Batches (Takes up remaining width or full width on mobile)
                        Expanded(
                          flex: size.width > 900 ? 2 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Batches',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Card(
                                child: stats.recentBatches.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(AppSizes.lg),
                                      child: Center(child: Text('No batches found.')),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: stats.recentBatches.length,
                                      separatorBuilder: (_, _) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final batch = stats.recentBatches[index];
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: colors.surfaceContainerHighest,
                                            child: Text('${index + 1}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                                          ),
                                          title: Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('Code: ${batch.code}'),
                                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                        );
                                      },
                                    ),
                              ),
                            ],
                          ),
                        ),


                // Spacing
                if (size.width > 900) const SizedBox(width: AppSizes.lg),

                // Quick Actions (Sidebar on Desktop/Tablet)
                if (size.width > 900)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildActionButton(context, 'Take Attendance', Icons.fact_check, colors.primary),
                                const SizedBox(height: AppSizes.sm),
                                _buildActionButton(context, 'Add New Student', Icons.person_add, colors.secondary),
                                const SizedBox(height: AppSizes.sm),
                                _buildActionButton(context, 'Create Homework', Icons.upload_file, Colors.blueGrey),
                                const SizedBox(height: AppSizes.sm),
                                _buildActionButton(context, 'View Reports', Icons.bar_chart, Colors.orange),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Icon(icon, color: color, size: AppSizes.iconLg),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSizes.md),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
