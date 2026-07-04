import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Apple Health styled summary analytics row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                  children: [
                    // First Card
                    isWide 
                      ? Expanded(child: _buildFeeCard('Total Collected', '₹1,45,000', true, theme, colors))
                      : _buildFeeCard('Total Collected', '₹1,45,000', true, theme, colors),
                    
                    if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                    
                    // Second Card
                    isWide 
                      ? Expanded(child: _buildFeeCard('Outstanding', '₹38,000', false, theme, colors))
                      : _buildFeeCard('Outstanding', '₹38,000', false, theme, colors),
                  ],
                );
              }
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            // Pending Collections Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Collections',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.send, size: 14),
                  label: const Text('Remind All'),
                ),
              ],
            ).animate().fade(delay: 50.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),

            // List of outstanding collections
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                final studentNames = ['Kabir Singh', 'Diya Sen', 'Ananya Patel'];
                final batches = ['Class 12 - Physics', 'IIT-JEE Crash Course', 'Class 12 - Chemistry'];
                final dueAmounts = ['₹4,500', '₹12,000', '₹3,500'];
                final dueDates = ['June 25, 2026', 'July 01, 2026', 'June 28, 2026'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(LucideIcons.user, color: colors.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentNames[index],
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${batches[index]} • Due ${dueDates[index]}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                dueAmounts[index],
                                style: GoogleFonts.inter(
                                  textStyle: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Pay',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100), // Pill Shape
        ),
        icon: const Icon(LucideIcons.creditCard),
        label: const Text('Create Structure'),
      ),
    );
  }

  Widget _buildFeeCard(String title, String amount, bool isPositive, ThemeData theme, ColorScheme colors) {
    return Card(
      color: colors.primary.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, 
                  color: isPositive ? Colors.green : Colors.red, 
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              amount,
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
}
