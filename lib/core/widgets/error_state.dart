import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';

/// Centered error state with retry. Used when a data source fails so the
/// failure stays contained to one screen instead of crashing the app.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = AppStrings.somethingWentWrong,
    this.message,
    this.onRetry,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.incorrectFill,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 34, color: colors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle
                    .copyWith(color: colors.textPrimary)),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message!,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.body.copyWith(color: colors.textSecondary)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SecondaryButton(
                  label: AppStrings.retry,
                  icon: Icons.refresh,
                  onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
