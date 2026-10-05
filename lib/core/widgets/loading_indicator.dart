import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

/// Centered loading spinner with an optional label.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.label = AppStrings.loading});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(label,
              style: AppTypography.body.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
