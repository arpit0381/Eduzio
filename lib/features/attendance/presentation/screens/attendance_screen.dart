import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Intro
                Text(
                  'Manage Student Attendance',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Record student attendance daily or analyze batch performance statistics.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Grid Menu Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
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
                            icon: Icons.fact_check,
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
                            icon: Icons.qr_code_scanner,
                            color: Colors.orange.shade800,
                            onTap: () => context.push('/attendance/scan'),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                        // Card 3: Analytics & Reports
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildMenuCard(
                            context: context,
                            title: 'Reports & Analytics',
                            description: 'Generate monthly attendance reports, view charts and analyze individual stats.',
                            icon: Icons.analytics_outlined,
                            color: Colors.teal,
                            onTap: () => context.push('/attendance/reports'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 24),
              // Action Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Open Module',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
