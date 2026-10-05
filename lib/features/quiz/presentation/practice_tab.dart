import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/subject_card.dart';
import '../../../routes/app_router.dart';
import '../../chapters/domain/chapter.dart';
import '../../chapters/state/chapter_provider.dart';
import '../domain/quiz_config.dart';

/// Practice Center: entry points for all four quiz modes.
class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  late int _quizLength;

  @override
  void initState() {
    super.initState();
    _quizLength = context.read<PrefsService>().preferredQuizLength;
  }

  Future<void> _pickChapter(
      BuildContext context, ValueChanged<Chapter> onPicked) async {
    final chapters = context.read<ChapterProvider>().chapters;
    final picked = await showModalBottomSheet<Chapter>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SectionHeader(title: 'Select Chapter'),
            ),
            // Nine chapters do not fit the sheet's default height (9/16 of
            // the screen), so the list scrolls instead of overflowing.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                children: [
                  for (final chapter in chapters)
                    ListTile(
                      leading: Text(chapter.emoji,
                          style: const TextStyle(fontSize: 20)),
                      title: Text('Chap ${chapter.order}: ${chapter.title}',
                          style: AppTypography.bodyMedium),
                      onTap: () => Navigator.of(context).pop(chapter),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  void _startQuiz(QuizConfig config) {
    Navigator.of(context).pushNamed(AppRoutes.quiz, arguments: config);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.practiceCenter)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SectionHeader(title: 'Quiz Modes'),
          const SizedBox(height: AppSpacing.md),
          SubjectCard(
            title: AppStrings.practiceMode,
            icon: Icons.school_outlined,
            meta: AppStrings.practiceModeDesc,
            onTap: () => _pickChapter(context,
                (chapter) => _startQuiz(QuizConfig.chapterPractice(chapter))),
          ),
          const SizedBox(height: AppSpacing.md),
          SubjectCard(
            title: AppStrings.timedTest,
            icon: Icons.timer_outlined,
            meta: '${AppStrings.timedTestDesc} • '
                '${AppConstants.timedSecondsPerQuestion}s per question',
            onTap: () => _pickChapter(
                context,
                (chapter) =>
                    _startQuiz(QuizConfig.timedTest(chapter, _quizLength))),
          ),
          const SizedBox(height: AppSpacing.md),
          SubjectCard(
            title: AppStrings.fullExam,
            icon: Icons.assignment_outlined,
            meta: '${AppStrings.fullExamDesc} • '
                '${AppConstants.fullExamMinutes} minutes',
            onTap: () => _startQuiz(QuizConfig.fullExam()),
          ),
          const SizedBox(height: AppSpacing.md),
          SubjectCard(
            title: AppStrings.mockExam,
            icon: Icons.workspace_premium_outlined,
            meta: '${AppStrings.mockExamDesc} • '
                '${AppConstants.mockExamLength} questions',
            onTap: () =>
                _startQuiz(QuizConfig.mockExam(AppConstants.mockExamLength)),
          ),
          const SizedBox(height: AppSpacing.md),
          SubjectCard(
            title: AppStrings.bookmarkedQuestions,
            icon: Icons.bookmark_outline,
            meta: AppStrings.bookmarkedQuestionsDesc,
            onTap: () => _startQuiz(QuizConfig.bookmarked()),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Questions per Timed Test'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            children: [
              for (final choice in AppConstants.quizLengthChoices)
                ChoiceChip(
                  label: Text('$choice'),
                  selected: _quizLength == choice,
                  selectedColor: colors.primary,
                  labelStyle: AppTypography.meta.copyWith(
                    color: _quizLength == choice
                        ? Colors.white
                        : colors.textPrimary,
                  ),
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _quizLength = choice);
                    context
                        .read<PrefsService>()
                        .setPreferredQuizLength(choice);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
