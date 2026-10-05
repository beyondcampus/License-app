import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/code_block.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/explanation_box.dart';
import '../../../core/widgets/formula_block.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/option_button.dart';
import '../../../core/widgets/progress_card.dart';
import '../../../routes/app_router.dart';
import '../domain/quiz_config.dart';
import '../state/quiz_provider.dart';
import 'quiz_results_screen.dart';

/// The MCQ engine screen (HTML screen 4): question, options with feedback
/// states, explanation, bookmark, navigation, timer and exit confirmation.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.config});

  final QuizConfig config;

  @override
  Widget build(BuildContext context) {
    final deps = context.read<AppDependencies>();
    return ChangeNotifierProvider(
      create: (_) => QuizProvider(
        config: config,
        questions: deps.questionRepository,
        bookmarks: deps.bookmarkRepository,
        results: deps.resultsRepository,
        practice: deps.practiceProgressRepository,
      )..load(),
      child: _QuizView(config: config),
    );
  }
}

class _QuizView extends StatefulWidget {
  const _QuizView({required this.config});

  final QuizConfig config;

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  bool _navigatedToResults = false;

  Future<bool> _confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.exitQuizTitle),
        content: const Text(AppStrings.exitQuizMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.exit,
                style: TextStyle(color: context.appColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final session = provider.session;

    // Hand off to results exactly once when the quiz finishes.
    if (provider.state == QuizState.finished &&
        provider.outcome != null &&
        !_navigatedToResults) {
      _navigatedToResults = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.results,
          arguments: QuizResultsArgs(
            outcome: provider.outcome!,
            config: widget.config,
            timeExpired: provider.timeExpired,
          ),
        );
      });
    }

    final quizInProgress =
        provider.state == QuizState.ready && session != null;

    return PopScope(
      canPop: !quizInProgress,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await _confirmExit(context);
        if (exit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.config.title, overflow: TextOverflow.ellipsis),
          actions: [
            // Only Timed Test and Full Exam run against a clock.
            if (quizInProgress && provider.isTimed)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: TimerBadge(
                    label:
                        AppDateUtils.formatDuration(provider.remainingSeconds),
                  ),
                ),
              ),
          ],
        ),
        body: switch (provider.state) {
          QuizState.loading => const LoadingIndicator(),
          QuizState.error => ErrorState(
              message: provider.errorMessage, onRetry: provider.load),
          QuizState.empty => EmptyState(
              icon: Icons.quiz_outlined,
              title: AppStrings.noData,
              message: widget.config.mode.name == 'bookmarked'
                  ? AppStrings.noBookmarksMessage
                  : 'No questions available for this selection yet.',
            ),
          QuizState.allCorrect => EmptyState(
              icon: Icons.emoji_events_outlined,
              title: AppStrings.allAnsweredCorrectly(provider.skippedCorrect),
              message: AppStrings.allAnsweredCorrectlyMessage,
              actionLabel: AppStrings.practiceAllAgain,
              onAction: provider.practiceAll,
            ),
          QuizState.finished => const LoadingIndicator(),
          QuizState.ready => _buildQuestion(context, provider),
        },
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, QuizProvider provider) {
    final colors = context.appColors;
    final session = provider.session!;
    final question = session.current;
    final selection = session.currentSelection;
    final locked = session.isCurrentLocked;
    final showFeedback = locked && session.immediateFeedback;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.question} ${session.currentIndex + 1} '
                      'of ${session.total}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body
                          .copyWith(color: colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(AppStrings.singleChoice,
                      style: AppTypography.body
                          .copyWith(color: colors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppProgressBar(
                  value: (session.currentIndex + 1) / session.total),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(question.questionText,
                        style: AppTypography.questionText
                            .copyWith(color: colors.textPrimary)),
                    if (question.formula != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      FormulaBlock(latex: question.formula),
                    ],
                    if (question.codeSnippet != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      CodeBlock(
                        code: question.codeSnippet!,
                        language: question.codeLanguage ?? 'cpp',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0; i < question.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: OptionButton(
                          label:
                              '${String.fromCharCode(65 + i)}. ${question.options[i]}',
                          state: _optionState(
                              i, selection, question.correctIndex,
                              showFeedback: showFeedback, locked: locked),
                          onTap: locked
                              ? null
                              : () => provider.selectOption(i),
                        ),
                      ),
                    if (showFeedback) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _AnswerVerdict(
                        isCorrect: selection == question.correctIndex,
                        correctLabel:
                            '${String.fromCharCode(65 + question.correctIndex)}. '
                            '${question.options[question.correctIndex]}',
                      ),
                    ],
                    if (showFeedback && question.explanation.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ExplanationBox(
                        title: AppStrings.explanation,
                        text: question.explanation,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              if (session.canGoPrevious) ...[
                SizedBox(
                  width: 48,
                  child: OutlinedButton(
                    onPressed: provider.previous,
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero),
                    child: const Icon(Icons.chevron_left, size: 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
              ],
              Expanded(
                child: SecondaryButton(
                  label: provider.isCurrentBookmarked
                      ? AppStrings.bookmarked
                      : AppStrings.bookmark,
                  icon: provider.isCurrentBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  onPressed: provider.toggleBookmark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: PrimaryButton(
                  label: session.isLastQuestion
                      ? AppStrings.finishQuiz
                      : AppStrings.nextQuestion,
                  onPressed: provider.next,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  OptionState _optionState(
    int index,
    int? selection,
    int correctIndex, {
    required bool showFeedback,
    required bool locked,
  }) {
    if (showFeedback) {
      if (index == correctIndex) return OptionState.correct;
      if (index == selection) return OptionState.incorrect;
      return OptionState.disabled;
    }
    if (index == selection) return OptionState.selected;
    return locked ? OptionState.disabled : OptionState.idle;
  }
}

/// One-line verdict shown under the options once an answer is locked in:
/// "Correct", or "Wrong — correct answer: C. …".
class _AnswerVerdict extends StatelessWidget {
  const _AnswerVerdict({required this.isCorrect, required this.correctLabel});

  final bool isCorrect;
  final String correctLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isCorrect ? colors.success : colors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 18,
              color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isCorrect
                  ? AppStrings.correct
                  : 'Wrong — correct answer: $correctLabel',
              style: AppTypography.metaBold.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
