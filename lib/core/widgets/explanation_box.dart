import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Blue tinted info box matching the HTML `.explanation-box`.
class ExplanationBox extends StatelessWidget {
  const ExplanationBox({super.key, required this.text, this.title});

  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.explanationFill,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: colors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: AppTypography.metaBold
                    .copyWith(color: colors.explanationText)),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(text,
              style:
                  AppTypography.meta.copyWith(color: colors.explanationText)),
        ],
      ),
    );
  }
}
