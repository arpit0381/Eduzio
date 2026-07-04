import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/sizes.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Intro
                Text(
                  'Manage Student Attendance',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Record student attendance daily or analyze batch performance statistics.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Grid Menu Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card 1: Mark Attendance
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildMenuCard(
                            context: context,
                            title: 'Mark Attendance',
                            description: 'Select a batch and date to record present/absent/late registers.',
                            icon: LucideIcons.clipboardCheck,
                            color: colors.primary,
                            onTap: () => context.push('/attendance/take'),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                        // Card 2: QR Scanner
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildMenuCard(
                            context: context,
                            title: 'QR ID Card Scan',
                            description: 'Scan student ID card QR codes for instantaneous daily check-ins.',
                            icon: LucideIcons.qrCode,
                            color: Colors.orange,
                            onTap: () => context.push('/attendance/scan'),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                        // Card 3: Analytics & Reports
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildMenuCard(
                            context: context,
                            title: 'Reports & Stats',
                            description: 'Generate monthly attendance reports, view charts and analyze individual stats.',
                            icon: LucideIcons.barChart3,
                            color: Colors.teal,
                            onTap: () => context.push('/attendance/reports'),
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Action Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 14, color: color),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
