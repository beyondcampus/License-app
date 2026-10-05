import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'progress_card.dart';

/// Tappable card matching the HTML `.subject-card`: leading emoji/icon chip,
/// title, meta line, optional progress bar and trailing badges.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.title,
    this.emoji,
    this.icon,
    this.meta,
    this.progress,
    this.badges = const [],
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? emoji;
  final IconData? icon;
  final String? meta;

  /// Progress in [0, 1]; hidden when null.
  final double? progress;
  final List<Widget> badges;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null || icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryFill,
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: emoji != null
                      ? Text(emoji!, style: const TextStyle(fontSize: 20))
                      : Icon(icon, size: 20, color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
              ],
              Expanded(
                child: Text(title,
                    style: AppTypography.cardTitle
                        .copyWith(color: colors.textPrimary)),
              ),
              ?trailing,
            ],
          ),
          if (meta != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(meta!,
                style: AppTypography.meta.copyWith(color: colors.textSecondary)),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 6, runSpacing: 6, children: badges),
          ],
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            AppProgressBar(value: progress!),
          ],
        ],
      ),
    );
  }
}
