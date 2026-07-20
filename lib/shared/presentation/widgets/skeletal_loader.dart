import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletalLoaderScreen extends StatelessWidget {
  const SkeletalLoaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
        : Colors.grey.shade200;
    final highlightColor = isDark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.6)
        : Colors.grey.shade100;

    Widget skeletonBox({
      required double height,
      double width = double.infinity,
      double borderRadius = 12.0,
    }) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1200.ms,
            color: highlightColor,
          );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Skeleton (Profile avatar + title)
              Row(
                children: [
                  skeletonBox(height: 48, width: 48, borderRadius: 24),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skeletonBox(height: 16, width: 140, borderRadius: 8),
                      const SizedBox(height: 8),
                      skeletonBox(height: 12, width: 90, borderRadius: 6),
                    ],
                  ),
                  const Spacer(),
                  skeletonBox(height: 40, width: 40, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 28),

              // Banner / Welcome Skeleton
              skeletonBox(height: 120, borderRadius: 20),
              const SizedBox(height: 28),

              // Section Header Skeleton
              skeletonBox(height: 18, width: 160, borderRadius: 8),
              const SizedBox(height: 16),

              // 2x2 Grid Stats Skeleton
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    4,
                    (index) => skeletonBox(height: 100, borderRadius: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // List Item Skeletons
              Column(
                children: List.generate(
                  2,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: skeletonBox(height: 64, borderRadius: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
