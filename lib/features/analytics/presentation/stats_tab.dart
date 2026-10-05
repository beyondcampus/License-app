import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/math_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_header.dart';
import '../state/analytics_provider.dart';
import 'chapter_bar_chart.dart';

/// Stats tab (HTML screen 6): latest score, accuracy by chapter,
/// weak topics and data-driven recommendations.
class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final provider = context.watch<AnalyticsProvider>();

    Widget body;
    if (!provider.loaded || provider.loading) {
      body = const LoadingIndicator();
    } else if (provider.error != null) {
      body = ErrorState(message: provider.error, onRetry: provider.load);
    } else if (!provider.hasHistory) {
      body = const EmptyState(
        icon: Icons.insights_outlined,
        title: AppStrings.noData,
        message: AppStrings.takeFirstQuiz,
      );
    } else {
      final latest = provider.latestResult!;
      body = RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            AppCard(
              child: Column(
                children: [
                  Text(AppStrings.latestMockScore,
                      style: AppTypography.meta
                          .copyWith(color: colors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${latest.correct} / ${latest.total}',
                    style: AppTypography.scoreDisplay
                        .copyWith(color: colors.success),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${(latest.accuracy * 100).round()}% Accuracy Rate • '
                    '${provider.totalQuizzes} '
                    '${provider.totalQuizzes == 1 ? 'quiz' : 'quizzes'} taken',
                    style: AppTypography.meta
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: AppStrings.accuracyByChapter),
            const SizedBox(height: AppSpacing.md),
            AppCard(child: ChapterBarChart(data: provider.chapterAccuracy)),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: AppStrings.topicsToReview),
            const SizedBox(height: AppSpacing.md),
            if (provider.weakTopics.isEmpty)
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined,
                        size: 18, color: colors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'No weak topics detected from your answers so far.',
                        style: AppTypography.meta
                            .copyWith(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              AppCard(
                child: Column(
                  children: [
                    for (final topic in provider.weakTopics) ...[
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: colors.warning),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${topic.topicTitle} (${topic.chapterTitle})',
                              style: AppTypography.meta
                                  .copyWith(color: colors.textPrimary),
                            ),
                          ),
                          Text(
                            MathUtils.percentLabel(
                                topic.accuracy * 100, 100),
                            style: AppTypography.metaBold
                                .copyWith(color: colors.warning),
                          ),
                        ],
                      ),
                      if (topic != provider.weakTopics.last)
                        Divider(height: 16, color: colors.border),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: AppStrings.recommendations),
            const SizedBox(height: AppSpacing.md),
            for (final rec in provider.recommendations) ...[
              AppCard(
                padding: AppSpacing.compactCardPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        size: 18, color: colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(rec,
                          style: AppTypography.meta
                              .copyWith(color: colors.textSecondary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.resultsAndAnalytics)),
      body: body,
    );
  }
}
