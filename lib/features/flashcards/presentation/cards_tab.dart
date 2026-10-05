import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../chapters/state/chapter_provider.dart';
import '../data/flashcard_repository.dart';
import '../domain/flashcard.dart';
import '../state/flashcard_provider.dart';
import 'flashcard_widget.dart';

/// Cards tab (HTML screen 7): due-card review with flip animation and
/// Hard / Good / Easy spaced-repetition grading.
class CardsTab extends StatelessWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.flashcards),
        actions: [
          if (provider.current != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${provider.positionLabel} / ${provider.sessionTotal}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: Builder(builder: (context) {
        if (!provider.loaded || provider.loading) {
          return const LoadingIndicator();
        }
        if (provider.error != null) {
          return ErrorState(message: provider.error, onRetry: provider.load);
        }
        if (provider.sessionDone) {
          return EmptyState(
            icon: Icons.celebration_outlined,
            title: AppStrings.allCaughtUp,
            message: AppStrings.noCardsDue,
            actionLabel: AppStrings.retry,
            onAction: provider.load,
          );
        }
        final card = provider.current!;
        final topicTitle = _topicTitle(context, card);
        return ListView(
          padding: AppSpacing.screenPadding,
          children: [
            FlashcardWidget(
              topicLabel: topicTitle,
              front: card.card.front,
              back: card.card.back,
              isFlipped: provider.isFlipped,
              onTap: provider.flip,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _GradeButton(
                    label: AppStrings.hard,
                    sublabel: provider.intervalLabel(ReviewGrade.hard),
                    color: context.appColors.error,
                    onTap: () => provider.grade(ReviewGrade.hard),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _GradeButton(
                    label: AppStrings.good,
                    sublabel: provider.intervalLabel(ReviewGrade.good),
                    color: context.appColors.yellow,
                    onTap: () => provider.grade(ReviewGrade.good),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _GradeButton(
                    label: AppStrings.easy,
                    sublabel: provider.intervalLabel(ReviewGrade.easy),
                    color: context.appColors.success,
                    onTap: () => provider.grade(ReviewGrade.easy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                '${provider.dueCount} ${AppStrings.cardsDue}',
                style: AppTypography.meta
                    .copyWith(color: context.appColors.textSecondary),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _topicTitle(BuildContext context, DueCard card) {
    final chapters = context.read<ChapterProvider>();
    final topics = chapters.topicsByChapter[card.card.chapterId] ?? const [];
    final topic =
        topics.where((t) => t.id == card.card.topicId).firstOrNull;
    if (topic != null) return topic.title;
    final chapter = chapters.chapters
        .where((c) => c.id == card.card.chapterId)
        .firstOrNull;
    return chapter?.title ?? '';
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label $sublabel',
      child: Material(
        color: color,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(label,
                    style: AppTypography.metaBold
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text(sublabel,
                    style: AppTypography.navLabel
                        .copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
