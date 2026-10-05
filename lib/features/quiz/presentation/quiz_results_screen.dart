import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/math_utils.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/progress_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes/app_router.dart';
import '../../chapters/state/chapter_provider.dart';
import '../domain/question.dart';
import '../domain/quiz_config.dart';
import '../domain/quiz_result.dart';
import '../domain/quiz_session.dart';

/// Arguments for the quiz results route.
class QuizResultsArgs {
  const QuizResultsArgs({
    required this.outcome,
    required this.config,
    this.timeExpired = false,
  });

  final QuizOutcome outcome;
  final QuizConfig config;
  final bool timeExpired;
}

/// Post-quiz results: score, accuracy, timing and per-question stats.
/// (Topic-level breakdown and recommendations live in the Stats tab.)
class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key, required this.args});

  final QuizResultsArgs args;

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  QuizResultsArgs get args => widget.args;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final result = args.outcome.result;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.quizResults)),
      // Ads disabled temporarily.
      // bottomNavigationBar: const AdBannerSlot(),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          if (args.timeExpired) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.timerFill,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: colors.error),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_off_outlined,
                    size: 18,
                    color: colors.timerText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.timeUp,
                      style: AppTypography.meta.copyWith(
                        color: colors.timerText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (args.config.mode == QuizMode.fullExam)
            _fullExamScoreCard(context)
          else
          AppCard(
            child: Column(
              children: [
                Text(
                  args.config.title,
                  style: AppTypography.meta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${result.correct} / ${result.total}',
                  style: AppTypography.scoreDisplay.copyWith(
                    color: result.scoreRatio >= 0.5
                        ? colors.success
                        : colors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${MathUtils.percent(result.correct, result.total)}% Score '
                  '• ${(result.accuracy * 100).round()}% ${AppStrings.accuracy}',
                  style: AppTypography.meta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: AppStrings.correct,
                  value: '${result.correct}',
                  color: colors.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  label: AppStrings.incorrect,
                  value: '${result.incorrect}',
                  color: colors.error,
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  label: AppStrings.unanswered,
                  value: '${result.unanswered}',
                  color: colors.textSecondary,
                  icon: Icons.remove_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: AppStrings.timeTaken,
                  value: AppDateUtils.formatDuration(result.timeSeconds),
                  color: colors.primary,
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  label: AppStrings.avgTimePerQuestion,
                  value: '${result.avgSecondsPerQuestion.toStringAsFixed(1)}s',
                  color: colors.warning,
                  icon: Icons.speed_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (args.config.mode == QuizMode.fullExam)
            ..._chapterBreakdown(context)
          else
            ..._topicBreakdown(context),
          if (args.config.mode == QuizMode.mock ||
              args.config.mode == QuizMode.fullExam) ...[
            const SizedBox(height: AppSpacing.lg),
            ..._mockAnswerReview(context),
          ],
          const SizedBox(height: AppSpacing.xl),
          ActionRow(
            children: [
              SecondaryButton(
                label: AppStrings.restartQuiz,
                icon: Icons.refresh,
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(AppRoutes.quiz, arguments: args.config),
              ),
              PrimaryButton(
                label: AppStrings.backToHome,
                icon: Icons.home_outlined,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on _QuizResultsScreenState {
  /// Exam-hall style score: marks out of the paper total (one mark per
  /// question) and the answer counts. There is no pass mark.
  Widget _fullExamScoreCard(BuildContext context) {
    final colors = context.appColors;
    final outcome = args.outcome;
    final result = outcome.result;
    final scored = outcome.marksScored;
    final max = outcome.maxMarks;

    return AppCard(
      child: Column(
        children: [
          Text(
            args.config.title,
            style: AppTypography.meta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$scored / $max',
            style: AppTypography.scoreDisplay.copyWith(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Marks obtained',
            style: AppTypography.metaBold.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Correct ${result.correct}  •  Wrong ${result.incorrect}  •  '
            'Not answered ${result.unanswered}',
            textAlign: TextAlign.center,
            style: AppTypography.meta.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Per-topic performance rows for THIS quiz, computed from its attempts.
  List<Widget> _topicBreakdown(BuildContext context) {
    final colors = context.appColors;
    final chapterProvider = context.read<ChapterProvider>();
    final topicTitles = {
      for (final topics in chapterProvider.topicsByChapter.values)
        for (final t in topics) t.id: t.title,
    };

    final byTopic = <String, List<bool>>{};
    for (final attempt in args.outcome.attempts) {
      if (attempt.selectedIndex < 0) continue;
      byTopic.putIfAbsent(attempt.topicId, () => []).add(attempt.isCorrect);
    }
    if (byTopic.length < 2) return const [];

    final entries = byTopic.entries.toList()
      ..sort((a, b) {
        final accA = a.value.where((c) => c).length / a.value.length;
        final accB = b.value.where((c) => c).length / b.value.length;
        return accA.compareTo(accB);
      });

    return [
      const SectionHeader(title: AppStrings.topicPerformance),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          children: [
            for (final entry in entries) ...[
              Builder(
                builder: (context) {
                  final correct = entry.value.where((c) => c).length;
                  final total = entry.value.length;
                  final ratio = MathUtils.ratio(correct, total);
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              topicTitles[entry.key] ?? entry.key,
                              style: AppTypography.meta.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$correct/$total • ${MathUtils.percent(correct, total)}%',
                            style: AppTypography.metaBold.copyWith(
                              color: ratio >= 0.6
                                  ? colors.success
                                  : colors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AppProgressBar(
                        value: ratio,
                        color: ratio >= 0.6 ? colors.success : colors.warning,
                      ),
                      if (entry != entries.last)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// Full exam: marks per chapter (every question counts, unanswered = 0).
  List<Widget> _chapterBreakdown(BuildContext context) {
    final colors = context.appColors;
    final chapters = context.read<ChapterProvider>().chapters;
    final outcome = args.outcome;
    final scored = <String, int>{};
    final total = <String, int>{};
    for (var i = 0; i < outcome.questions.length; i++) {
      final chapterId = outcome.questions[i].chapterId;
      total[chapterId] = (total[chapterId] ?? 0) + 1;
      if (i < outcome.attempts.length && outcome.attempts[i].isCorrect) {
        scored[chapterId] = (scored[chapterId] ?? 0) + 1;
      }
    }
    final rows = [
      for (final c in chapters)
        if (total.containsKey(c.id)) c,
    ];
    if (rows.isEmpty) return const [];

    return [
      const SectionHeader(title: 'Marks by chapter'),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          children: [
            for (final c in rows) ...[
              Builder(
                builder: (context) {
                  final got = scored[c.id] ?? 0;
                  final of = total[c.id]!;
                  final ratio = MathUtils.ratio(got, of);
                  final color = colors.primary;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chap ${c.order}: ${c.title}',
                              style: AppTypography.meta.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$got / $of',
                            style: AppTypography.metaBold.copyWith(color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AppProgressBar(value: ratio, color: color),
                      if (c != rows.last) const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _mockAnswerReview(BuildContext context) {
    return [
      _AnswerReview(outcome: args.outcome),
    ];
  }
}

enum _ReviewFilter { all, wrong, unanswered, correct }

/// Every question of a finished mock or full exam with the user's answer,
/// filterable so a 100-question paper stays easy to go through.
class _AnswerReview extends StatefulWidget {
  const _AnswerReview({required this.outcome});

  final QuizOutcome outcome;

  @override
  State<_AnswerReview> createState() => _AnswerReviewState();
}

class _AnswerReviewState extends State<_AnswerReview> {
  _ReviewFilter _filter = _ReviewFilter.all;

  _ReviewFilter _statusOf(Question q, QuestionAttempt? a) {
    final selected = a?.selectedIndex ?? -1;
    if (selected < 0 || selected >= q.options.length) {
      return _ReviewFilter.unanswered;
    }
    return selected == q.correctIndex ? _ReviewFilter.correct : _ReviewFilter.wrong;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final questions = widget.outcome.questions;
    final attemptsByQuestion = {
      for (final attempt in widget.outcome.attempts) attempt.questionId: attempt,
    };
    final status = [
      for (final q in questions) _statusOf(q, attemptsByQuestion[q.id]),
    ];
    int count(_ReviewFilter f) =>
        f == _ReviewFilter.all ? questions.length : status.where((s) => s == f).length;
    const labels = {
      _ReviewFilter.all: 'All',
      _ReviewFilter.wrong: 'Wrong',
      _ReviewFilter.unanswered: 'Not answered',
      _ReviewFilter.correct: 'Correct',
    };
    final shown = [
      for (var i = 0; i < questions.length; i++)
        if (_filter == _ReviewFilter.all || status[i] == _filter) i,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Answer review'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final f in _ReviewFilter.values)
              ChoiceChip(
                label: Text('${labels[f]} (${count(f)})'),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (shown.isEmpty)
          Text(
            'No questions in this group.',
            style: AppTypography.meta.copyWith(color: colors.textSecondary),
          ),
        for (final index in shown) ...[
          _MockAnswerCard(
            number: index + 1,
            question: questions[index],
            attempt: attemptsByQuestion[questions[index].id],
            colors: colors,
          ),
          if (index != shown.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _MockAnswerCard extends StatelessWidget {
  const _MockAnswerCard({
    required this.number,
    required this.question,
    required this.attempt,
    required this.colors,
  });

  final int number;
  final Question question;
  final QuestionAttempt? attempt;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = attempt?.selectedIndex ?? -1;
    final answered =
        selectedIndex >= 0 && selectedIndex < question.options.length;
    final isCorrect = answered && selectedIndex == question.correctIndex;

    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$number. ${question.questionText}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                answered
                    ? (isCorrect
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined)
                    : Icons.remove_circle_outline,
                color: answered
                    ? (isCorrect ? colors.success : colors.error)
                    : colors.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < question.options.length; index++) ...[
            _ReviewOption(
              index: index,
              text: question.options[index],
              isSelected: index == selectedIndex,
              isCorrect: index == question.correctIndex,
              selectedAnswerIsCorrect: isCorrect,
              colors: colors,
            ),
            if (index < question.options.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            isCorrect
                ? 'Correct'
                : '${answered ? 'Wrong' : 'Not answered'} — correct answer: '
                    '${String.fromCharCode(65 + question.correctIndex)}. '
                    '${question.options[question.correctIndex]}',
            style: AppTypography.metaBold.copyWith(
              color: isCorrect
                  ? colors.success
                  : (answered ? colors.error : colors.textSecondary),
            ),
          ),
          if (!isCorrect && question.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              question.explanation,
              style: AppTypography.meta.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewOption extends StatelessWidget {
  const _ReviewOption({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.selectedAnswerIsCorrect,
    required this.colors,
  });

  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool selectedAnswerIsCorrect;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final isGreen = isCorrect && (!isSelected || selectedAnswerIsCorrect);
    final color = isGreen
        ? colors.success
        : isSelected
        ? colors.error
        : colors.border;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${String.fromCharCode(65 + index)}.',
            style: AppTypography.bodyMedium.copyWith(color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          if (isSelected)
            Icon(
              isGreen ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: color,
            ),
          if (!isSelected && isCorrect)
            Icon(Icons.check_circle, size: 18, color: color),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.sectionTitle.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
