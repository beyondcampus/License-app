import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Thin animated progress bar matching the HTML `.progress-bar-*` (8px track).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  /// Progress in [0, 1].
  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: colors.border),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              widthFactor: clamped,
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? colors.primary,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labeled progress card, e.g. the dashboard "Overall Readiness" card.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;

  /// Progress in [0, 1].
  final double value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pct = trailing ?? '${(value.clamp(0.0, 1.0) * 100).round()}%';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTypography.body
                      .copyWith(color: colors.textSecondary)),
              Text(pct,
                  style: AppTypography.bodyMedium
                      .copyWith(color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(value: value),
        ],
      ),
    );
  }
}
