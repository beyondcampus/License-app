import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../analytics/data/results_repository.dart';
import '../../bookmarks/data/bookmark_repository.dart';
import '../../bookmarks/domain/bookmark.dart';
import '../data/practice_progress_repository.dart';
import '../data/question_repository.dart';
import '../domain/question.dart';
import '../domain/quiz_config.dart';
import '../domain/quiz_result.dart';
import '../domain/quiz_session.dart';

/// [allCorrect]: topic practice where every question's latest Practice
/// answer is already correct — nothing is left to practise.
enum QuizState { loading, ready, empty, allCorrect, error, finished }

/// Runs one quiz: loads questions per [QuizConfig], owns the session and the
/// timer, persists the outcome on finish. Screen-scoped provider.
class QuizProvider extends ChangeNotifier {
  QuizProvider({
    required this.config,
    required this._questions,
    required this._bookmarks,
    required this._results,
    this._practice,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final QuizConfig config;
  final QuestionRepository _questions;
  final BookmarkRepository _bookmarks;
  final ResultsRepository _results;
  final PracticeProgressRepository? _practice;
  final DateTime Function() _clock;

  /// Topic practice: questions left out because their latest Practice answer
  /// is correct. [includeCorrect] ("Practice all again") keeps them in.
  int skippedCorrect = 0;
  bool includeCorrect = false;

  QuizState state = QuizState.loading;
  String? errorMessage;
  QuizSession? session;
  QuizOutcome? outcome;
  bool saveFailed = false;

  Timer? _timer;
  int elapsedSeconds = 0;
  int remainingSeconds = 0;
  bool get isTimed => config.timed;
  bool timeExpired = false;

  bool isCurrentBookmarked = false;

  int _timeLimitSeconds(int questionCount) =>
      config.mode == QuizMode.fullExam
          ? AppConstants.fullExamMinutes * 60
          : AppConstants.timedSecondsPerQuestion * questionCount;

  Future<void> load() async {
    state = QuizState.loading;
    notifyListeners();
    try {
      var loaded = await _loadQuestions();
      skippedCorrect = 0;
      if (config.skipCorrect && !includeCorrect && loaded.isNotEmpty) {
        final correct = await _correctQuestionIds();
        final left = loaded.where((q) => !correct.contains(q.id)).toList();
        skippedCorrect = loaded.length - left.length;
        if (left.isEmpty) {
          state = QuizState.allCorrect;
          notifyListeners();
          return;
        }
        loaded = left;
      }
      if (loaded.isEmpty) {
        state = QuizState.empty;
        notifyListeners();
        return;
      }
      session = QuizSession(
        questions: loaded,
        mode: config.mode,
        chapterId: config.chapterId,
        clock: _clock,
      );
      elapsedSeconds = 0;
      timeExpired = false;
      if (isTimed) {
        remainingSeconds = _timeLimitSeconds(loaded.length);
      }
      _startTimer();
      await _refreshBookmarkState();
      state = QuizState.ready;
    } catch (e) {
      debugPrint('QuizProvider.load: $e');
      errorMessage = e.toString();
      state = QuizState.error;
    }
    notifyListeners();
  }

  Future<List<Question>> _loadQuestions() async {
    List<Question> loaded;
    switch (config.mode) {
      case QuizMode.bookmarked:
        final marks = await _bookmarks.getByType(BookmarkType.question);
        loaded =
            await _questions.getByIds(marks.map((b) => b.itemId).toList());
      case QuizMode.fullExam:
        // The paper is complete as built; no length cap applies.
        return (await _questions.getFullExamPaper()).questions;
      case QuizMode.mock:
        loaded = await _questions.getMockSample(
            config.questionCount ?? AppConstants.mockExamLength);
      default:
        if (config.topicIds != null) {
          // A topic group runs its subtopics in syllabus order.
          final all = await _questions.getByTopics(config.topicIds!);
          loaded = [
            for (final topicId in config.topicIds!)
              ...all.where((q) => q.topicId == topicId),
          ];
        } else if (config.topicId != null) {
          loaded = await _questions.getByTopic(config.topicId!);
        } else if (config.chapterId != null) {
          loaded = [...await _questions.getByChapter(config.chapterId!)]
            ..shuffle(Random());
        } else {
          loaded = await _questions.getAll();
        }
    }
    final cap = config.questionCount;
    if (cap != null && loaded.length > cap) loaded = loaded.take(cap).toList();
    return loaded;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      if (isTimed) {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          remainingSeconds = 0;
          timeExpired = true;
          finishQuiz();
          return;
        }
      }
      notifyListeners();
    });
  }

  Future<void> _refreshBookmarkState() async {
    final s = session;
    if (s == null) return;
    isCurrentBookmarked =
        await _bookmarks.isBookmarked(BookmarkType.question, s.current.id);
  }

  Future<void> selectOption(int index) async {
    final s = session;
    if (s == null || state != QuizState.ready) return;
    if (!s.selectOption(index)) return;
    notifyListeners();
    // Practice answers lock at once; save each one so leaving midway keeps it.
    if (config.mode == QuizMode.practice) {
      final question = s.current;
      try {
        await _practice?.record(question.id,
            isCorrect: index == question.correctIndex);
      } catch (e) {
        debugPrint('QuizProvider: failed to save practice answer: $e');
      }
    }
  }

  /// "Practice all again": run every question, including the correct ones.
  Future<void> practiceAll() async {
    includeCorrect = true;
    await load();
  }

  /// Progress is optional: if it can't be read, practise every question.
  Future<Set<String>> _correctQuestionIds() async {
    try {
      return await _practice?.correctQuestionIds() ?? const {};
    } catch (e) {
      debugPrint('QuizProvider: failed to read practice progress: $e');
      return const {};
    }
  }

  Future<void> next() async {
    final s = session;
    if (s == null) return;
    if (s.isLastQuestion) {
      await finishQuiz();
      return;
    }
    s.next();
    await _refreshBookmarkState();
    notifyListeners();
  }

  Future<void> previous() async {
    final s = session;
    if (s == null || !s.canGoPrevious) return;
    s.previous();
    await _refreshBookmarkState();
    notifyListeners();
  }

  Future<void> toggleBookmark() async {
    final s = session;
    if (s == null) return;
    isCurrentBookmarked =
        await _bookmarks.toggle(BookmarkType.question, s.current.id);
    notifyListeners();
  }

  Future<void> finishQuiz() async {
    final s = session;
    if (s == null || state == QuizState.finished) return;
    _timer?.cancel();
    outcome = s.finish(elapsedSeconds: elapsedSeconds);
    state = QuizState.finished;
    saveFailed = false;
    try {
      await _results.saveResult(outcome!.result, outcome!.attempts);
    } catch (e) {
      // The user still sees their result; only history is affected.
      debugPrint('QuizProvider: failed to persist result: $e');
      saveFailed = true;
    }
    notifyListeners();
  }

  Future<void> restart() async {
    final s = session;
    if (s == null) return;
    s.restart();
    outcome = null;
    elapsedSeconds = 0;
    timeExpired = false;
    if (isTimed) {
      remainingSeconds = _timeLimitSeconds(s.questions.length);
    }
    state = QuizState.ready;
    _startTimer();
    await _refreshBookmarkState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
