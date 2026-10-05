import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/subject_card.dart';
import '../../../routes/app_router.dart';
import '../state/chapter_provider.dart';
import 'topic_list_screen.dart';

/// Chapters tab: every chapter with live stats and progress.
class ChaptersTab extends StatelessWidget {
  const ChaptersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChapterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navChapters)),
      body: switch (provider.state) {
        LoadState.initial || LoadState.loading => const LoadingIndicator(),
        LoadState.error => ErrorState(
          message: provider.errorMessage,
          onRetry: () => context.read<ChapterProvider>().load(),
        ),
        LoadState.ready => ListView.separated(
          padding: AppSpacing.screenPadding,
          itemCount: provider.chapters.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final chapter = provider.chapters[index];
            final stats = provider.statsByChapter[chapter.id];
            final topicCount =
                provider.topicCountByChapter[chapter.id] ??
                stats?.topicCount ??
                0;
            return SubjectCard(
              title: 'Chap ${chapter.order}: ${chapter.title}',
              emoji: chapter.emoji,
              meta: chapter.description,
              badges: const [],
              progress: provider.chapterCompletion(chapter.id),
              trailing: Text(
                '${topicCount} ${AppStrings.topics}'
                '${stats == null ? '' : '\n${stats.questionCount} ${AppStrings.mcqs}'}',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.topics,
                arguments: TopicListArgs(chapter: chapter),
              ),
            );
          },
        ),
      },
    );
  }
}
