import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes/app_router.dart';
import '../../chapters/presentation/topic_list_screen.dart';
import '../../chapters/state/chapter_provider.dart';
import '../../theory/presentation/theory_reader_screen.dart';
import '../state/search_provider.dart';

/// Global search across chapters, topics, theory, formulas and questions.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = context.read<AppDependencies>();
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(deps.contentSource),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final provider = context.watch<SearchProvider>();
    final results = provider.results;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: AppStrings.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          style: AppTypography.body.copyWith(color: colors.textPrimary),
          onChanged: (value) =>
              context.read<SearchProvider>().search(value),
        ),
      ),
      body: Builder(builder: (context) {
        if (provider.query.trim().isEmpty) {
          return const EmptyState(
            icon: Icons.search,
            title: AppStrings.search,
            message: 'Search chapters, topics, theory, formulas and '
                'questions.',
          );
        }
        if (provider.error != null && !provider.searching) {
          return ErrorState(
            message: provider.error,
            onRetry: () => context
                .read<SearchProvider>()
                .search(provider.query),
          );
        }
        if (results.isEmpty && !provider.searching) {
          return EmptyState(
            icon: Icons.search_off,
            title: AppStrings.noResults,
            message: 'Nothing matches "${provider.query}".',
          );
        }
        final chapterProvider = context.read<ChapterProvider>();
        return ListView(
          padding: AppSpacing.screenPadding,
          children: [
            if (results.chapters.isNotEmpty) ...[
              const SectionHeader(title: 'Chapters'),
              const SizedBox(height: AppSpacing.sm),
              for (final chapter in results.chapters)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(chapter.emoji,
                      style: const TextStyle(fontSize: 18)),
                  title: Text(chapter.title,
                      style: AppTypography.bodyMedium
                          .copyWith(color: colors.textPrimary)),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.topics,
                    arguments: TopicListArgs(chapter: chapter),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (results.topics.isNotEmpty) ...[
              const SectionHeader(title: 'Topics & Theory'),
              const SizedBox(height: AppSpacing.sm),
              for (final topic in results.topics)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.menu_book_outlined,
                      size: 20, color: colors.primary),
                  title: Text(topic.title,
                      style: AppTypography.bodyMedium
                          .copyWith(color: colors.textPrimary)),
                  subtitle: Text(topic.subtitle,
                      style: AppTypography.caption
                          .copyWith(color: colors.textSecondary)),
                  onTap: () {
                    // A parent group has no theory of its own: list its
                    // subtopics instead of opening an empty reader.
                    final chapters = context.read<ChapterProvider>();
                    final chapter = chapters.chapters
                        .where((c) => c.id == topic.chapterId)
                        .firstOrNull;
                    if (chapter != null && chapters.hasSubtopics(topic)) {
                      Navigator.of(context).pushNamed(
                        AppRoutes.topics,
                        arguments:
                            TopicListArgs(chapter: chapter, parent: topic),
                      );
                      return;
                    }
                    Navigator.of(context).pushNamed(
                      AppRoutes.theory,
                      arguments: TheoryReaderArgs(topic: topic),
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (results.formulas.isNotEmpty) ...[
              const SectionHeader(title: 'Formulas'),
              const SizedBox(height: AppSpacing.sm),
              for (final formula in results.formulas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.functions,
                      size: 20, color: colors.success),
                  title: Text(formula.title,
                      style: AppTypography.bodyMedium
                          .copyWith(color: colors.textPrimary)),
                  subtitle: Text(formula.plainText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption
                          .copyWith(color: colors.textSecondary)),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.formulas,
                    arguments: formula.chapterId,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (results.questions.isNotEmpty) ...[
              const SectionHeader(title: 'Questions'),
              const SizedBox(height: AppSpacing.sm),
              for (final question in results.questions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.quiz_outlined,
                      size: 20, color: colors.warning),
                  title: Text(question.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.meta
                          .copyWith(color: colors.textPrimary)),
                  onTap: () {
                    final topic = chapterProvider
                        .topicsByChapter[question.chapterId]
                        ?.where((t) => t.id == question.topicId)
                        .firstOrNull;
                    if (topic == null) return;
                    Navigator.of(context).pushNamed(
                      AppRoutes.theory,
                      arguments: TheoryReaderArgs(topic: topic),
                    );
                  },
                ),
            ],
          ],
        );
      }),
    );
  }
}
