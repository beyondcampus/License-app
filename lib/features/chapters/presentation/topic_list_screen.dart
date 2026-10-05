import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_tab_group.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/subject_card.dart';
import '../../../routes/app_router.dart';
import '../../quiz/domain/quiz_config.dart';
import '../../theory/presentation/theory_reader_screen.dart';
import '../domain/chapter.dart';
import '../domain/topic.dart';
import '../state/chapter_provider.dart';

/// Arguments for the topic list route.
///
/// Without [parent] the screen lists a chapter's top-level topics; with it,
/// the subtopics of that parent topic.
class TopicListArgs {
  const TopicListArgs({required this.chapter, this.parent});
  final Chapter chapter;
  final Topic? parent;
}

/// Topics of one chapter (or subtopics of one topic) with Theory / Practice
/// tabs (HTML screen 2).
///
/// Tapping a topic that has subtopics pushes this same screen for them;
/// tapping a leaf topic opens the theory reader.
class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key, required this.args});

  final TopicListArgs args;

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChapterProvider>().loadChapter(widget.args.chapter.id);
      }
    });
  }

  /// "1.2" for a top-level topic, "1.2.3" for a subtopic.
  String _number(Topic topic) {
    final parent = widget.args.parent;
    final chapter = widget.args.chapter;
    return parent == null
        ? '${chapter.order}.${topic.order}'
        : '${chapter.order}.${parent.order}.${topic.order}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final provider = context.watch<ChapterProvider>();
    final chapter = widget.args.chapter;
    final parent = widget.args.parent;
    final topics = parent == null
        ? provider.topLevelTopics(chapter.id)
        : provider.subtopicsOf(parent);

    return Scaffold(
      appBar: AppBar(
        title: Text(parent?.title ?? chapter.title,
            overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AppTabGroup(
              tabs: const [AppStrings.tabTheory, AppStrings.tabPractice],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: topics.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: AppStrings.noData,
                  )
                : ListView.separated(
                    padding: AppSpacing.screenPadding,
                    itemCount: topics.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      final isGroup = provider.hasSubtopics(topic);
                      final mcqCount = provider.questionCountFor(topic);
                      final completed = provider.isCompletedFor(topic);
                      final title = '${_number(topic)} ${topic.title}';

                      if (_tab == 1) {
                        // Practice tab: a group practises all its subtopics.
                        // Questions answered correctly in Practice are
                        // skipped, so the card counts what is left.
                        final correct = provider.practiceCorrectFor(topic);
                        final left = mcqCount - correct;
                        return SubjectCard(
                          title: title,
                          meta: correct == 0
                              ? '$mcqCount ${AppStrings.mcqs} • '
                                  '${AppStrings.practiceMode}'
                              : left <= 0
                              ? AppStrings.practiceAllCorrect(mcqCount)
                              : '${AppStrings.practiceLeft(left, mcqCount)} '
                                  '${AppStrings.mcqs}',
                          progress: mcqCount == 0 ? null : correct / mcqCount,
                          trailing: Icon(
                            left <= 0 && mcqCount > 0
                                ? Icons.check_circle
                                : Icons.play_circle_outline,
                            color: left <= 0 && mcqCount > 0
                                ? colors.success
                                : colors.primary,
                            size: 22,
                          ),
                          onTap: mcqCount == 0
                              ? null
                              : () async {
                                  await Navigator.of(context).pushNamed(
                                    AppRoutes.quiz,
                                    arguments: isGroup
                                        ? QuizConfig.subtopicsPractice(
                                            topic, provider.subtopicsOf(topic))
                                        : QuizConfig.topicPractice(topic),
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<ChapterProvider>()
                                        .refreshProgress();
                                  }
                                },
                        );
                      }

                      if (isGroup) {
                        final subtopics = provider.subtopicsOf(topic);
                        return SubjectCard(
                          title: title,
                          meta: topic.subtitle,
                          progress: provider.completionFor(topic),
                          trailing: Icon(Icons.chevron_right,
                              color: colors.textSecondary),
                          badges: [
                            if (completed)
                              InfoChip(
                                label: AppStrings.completed,
                                icon: Icons.check_circle_outline,
                                color: colors.success,
                              ),
                            InfoChip(
                              label:
                                  '${subtopics.length} ${AppStrings.subtopics}',
                              icon: Icons.account_tree_outlined,
                            ),
                            InfoChip(
                              label: '$mcqCount ${AppStrings.mcqs}',
                              icon: Icons.quiz_outlined,
                              color: colors.textSecondary,
                            ),
                          ],
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.topics,
                            arguments:
                                TopicListArgs(chapter: chapter, parent: topic),
                          ),
                        );
                      }

                      return SubjectCard(
                        title: title,
                        meta: topic.subtitle,
                        progress: provider.topicCompletion(topic.id),
                        badges: [
                          if (completed)
                            InfoChip(
                              label: AppStrings.completed,
                              icon: Icons.check_circle_outline,
                              color: colors.success,
                            ),
                          if (topic.hasFormulas)
                            const InfoChip(
                              label: AppStrings.tabFormulas,
                              icon: Icons.functions,
                            ),
                          if (topic.hasNotes)
                            InfoChip(
                              label: AppStrings.tabNotes,
                              icon: Icons.sticky_note_2_outlined,
                              color: colors.warning,
                            ),
                          InfoChip(
                            label: '$mcqCount ${AppStrings.mcqs}',
                            icon: Icons.quiz_outlined,
                            color: colors.textSecondary,
                          ),
                        ],
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.theory,
                            arguments: TheoryReaderArgs(topic: topic),
                          );
                          if (context.mounted) {
                            // Reflect progress made while reading.
                            context.read<ChapterProvider>().refreshProgress();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
