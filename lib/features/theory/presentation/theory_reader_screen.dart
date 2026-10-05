import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tab_group.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../routes/app_router.dart';
import '../../chapters/domain/topic.dart';
import '../../quiz/domain/quiz_config.dart';
import '../domain/theory_content.dart';
import '../state/theory_provider.dart';
import 'theory_block_view.dart';

/// Arguments for the theory reader route.
class TheoryReaderArgs {
  const TheoryReaderArgs({required this.topic});
  final Topic topic;
}

/// Theory reader: Concepts / Formulas / Notes tabs rendered from
/// [TheoryContent] blocks, with bookmark, completion and practice actions.
class TheoryReaderScreen extends StatelessWidget {
  const TheoryReaderScreen({super.key, required this.args});

  final TheoryReaderArgs args;

  @override
  Widget build(BuildContext context) {
    final deps = context.read<AppDependencies>();
    return ChangeNotifierProvider(
      create: (_) => TheoryProvider(
        topicId: args.topic.id,
        theory: deps.theoryRepository,
        bookmarks: deps.bookmarkRepository,
        progress: deps.progressRepository,
      )..load(),
      child: _TheoryReaderView(topic: args.topic),
    );
  }
}

class _TheoryReaderView extends StatelessWidget {
  const _TheoryReaderView({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final provider = context.watch<TheoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: provider.isBookmarked
                ? 'Remove bookmark'
                : AppStrings.bookmark,
            onPressed:
                provider.loading ? null : provider.toggleBookmark,
            icon: Icon(
              provider.isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: provider.isBookmarked
                  ? colors.error
                  : colors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.loading) return const LoadingIndicator();
          if (provider.error != null) {
            return ErrorState(
                message: provider.error, onRetry: provider.load);
          }
          final content = provider.content;
          if (content == null || content.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: AppStrings.noData,
              message: 'No study content available for this topic yet.',
            );
          }
          final blocks = switch (provider.tabIndex) {
            0 => content.concepts,
            1 => content.formulas,
            _ => content.notes,
          };
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: AppTabGroup(
                  tabs: const [
                    AppStrings.tabConcepts,
                    AppStrings.tabFormulas,
                    AppStrings.tabNotes,
                  ],
                  selectedIndex: provider.tabIndex,
                  onChanged: provider.setTab,
                ),
              ),
              Expanded(
                child: blocks.isEmpty
                    ? const EmptyState(
                        icon: Icons.notes_outlined,
                        title: AppStrings.noData,
                      )
                    : ListView(
                        padding: AppSpacing.screenPadding,
                        children: [
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final block in blocks) ...[
                                  TheoryBlockViewSpacing(block: block),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: provider.toggleCompleted,
                            icon: Icon(
                              provider.isCompleted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: provider.isCompleted
                                  ? colors.success
                                  : colors.textSecondary,
                            ),
                            label: Text(provider.isCompleted
                                ? AppStrings.completed
                                : AppStrings.markComplete),
                          ),
                        ],
                      ),
              ),
              // Ads disabled temporarily.
              // const AdBannerSlot(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: ActionRow(
                  children: [
                    SecondaryButton(
                      label: AppStrings.formulaSheet,
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.formulas,
                        arguments: topic.chapterId,
                      ),
                    ),
                    PrimaryButton(
                      label: AppStrings.practiceThisTopic,
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.quiz,
                        arguments: QuizConfig.topicPractice(topic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A theory block with its bottom spacing inside the content card.
class TheoryBlockViewSpacing extends StatelessWidget {
  const TheoryBlockViewSpacing({super.key, required this.block});

  final TheoryBlock block;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TheoryBlockView(block: block),
    );
  }
}
