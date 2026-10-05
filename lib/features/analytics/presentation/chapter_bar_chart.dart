import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../state/analytics_provider.dart';

/// Accuracy-by-chapter bar chart matching the HTML analytics screen:
/// one colored bar per chapter (blue / green / orange), 100px tall area.
class ChapterBarChart extends StatelessWidget {
  const ChapterBarChart({super.key, required this.data});

  final List<ChapterAccuracy> data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final barColors = [colors.primary, colors.success, colors.warning];

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < data.length; i++)
            Expanded(
              child: Semantics(
                label: '${data[i].title}: '
                    '${(data[i].accuracy * 100).round()} percent accuracy',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      data[i].attempted == 0
                          ? '—'
                          : '${(data[i].accuracy * 100).round()}%',
                      style: AppTypography.caption
                          .copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      height: 8 + 90 * data[i].accuracy.clamp(0.0, 1.0),
                      width: 24,
                      decoration: BoxDecoration(
                        color: data[i].attempted == 0
                            ? colors.border
                            : barColors[i % barColors.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data[i].shortTitle,
                      style: AppTypography.navLabel
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
