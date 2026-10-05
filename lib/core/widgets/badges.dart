import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Orange streak pill matching the HTML `.badge-streak` (🔥 5 Days).
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: '$days day study streak',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.streakFill,
          borderRadius: AppRadius.pillAll,
        ),
        child: Text(
          '🔥 $days ${days == 1 ? 'Day' : 'Days'}',
          style: AppTypography.metaBold.copyWith(color: colors.warning),
        ),
      ),
    );
  }
}

/// Red countdown pill matching the HTML `.timer-badge` (⏱ 28s).
class TimerBadge extends StatelessWidget {
  const TimerBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: 'Time remaining $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.timerFill,
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: colors.timerText),
            const SizedBox(width: 4),
            Text(label,
                style:
                    AppTypography.metaBold.copyWith(color: colors.timerText)),
          ],
        ),
      ),
    );
  }
}

/// Small labeled chip (used for topic badges like "Formulas", "Notes").
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = color ?? colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
