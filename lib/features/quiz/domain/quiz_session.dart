import 'question.dart';
import 'quiz_result.dart';

/// The outcome of a finished session, ready for persistence and display.
class QuizOutcome {
  const QuizOutcome({
    required this.result,
    required this.attempts,
    required this.questions,
    this.marks,
  });

  final QuizResult result;
  final List<QuestionAttempt> attempts;
  final List<Question> questions;

  /// Marks per question (aligned with [questions]); null = 1 mark each.
  final List<int>? marks;

  int marksOf(int index) => marks?[index] ?? 1;

  int get maxMarks {
    var sum = 0;
    for (var i = 0; i < questions.length; i++) {
      sum += marksOf(i);
    }
    return sum;
  }

  int get marksScored {
    var sum = 0;
    for (var i = 0; i < attempts.length; i++) {
      if (attempts[i].isCorrect) sum += marksOf(i);
    }
    return sum;
  }
}

/// Pure-Dart quiz engine: answer state, locking, scoring, per-question timing.
/// UI-free and fully unit-testable; the provider adds timers and persistence.
class QuizSession {
  QuizSession({
    required this.questions,
    required this.mode,
    this.chapterId,
    this.marks,
    DateTime Function()? clock,
  })  : assert(questions.isNotEmpty, 'QuizSession needs questions'),
        assert(marks == null || marks.length == questions.length,
            'marks must align with questions'),
        _clock = clock ?? DateTime.now {
    _questionShownAt = _clock();
  }

  final List<Question> questions;
  final QuizMode mode;
  final String? chapterId;

  /// Marks per question (full exam: 1 or 2); null = 1 mark each.
  final List<int>? marks;
  final DateTime Function() _clock;

  int marksOf(int index) => marks?[index] ?? 1;

  int _currentIndex = 0;
  final Map<int, int> _selections = {};
  final Set<int> _locked = {};
  final Map<int, int> _timeMs = {};
  late DateTime _questionShownAt;
  bool _finished = false;

  // --- Reading state ---

  int get currentIndex => _currentIndex;
  Question get current => questions[_currentIndex];
  int get total => questions.length;
  bool get isFinished => _finished;

  /// Practice-style modes and the full exam reveal correctness immediately
  /// and lock the answer.
  bool get immediateFeedback =>
      mode == QuizMode.practice ||
      mode == QuizMode.bookmarked ||
      mode == QuizMode.fullExam;

  int? selectionOf(int index) => _selections[index];
  int? get currentSelection => _selections[_currentIndex];
  bool isLocked(int index) => _locked.contains(index);
  bool get isCurrentLocked => isLocked(_currentIndex);

  bool get isCurrentCorrect =>
      currentSelection != null && currentSelection == current.correctIndex;

  int get answeredCount => _selections.length;
  bool get isLastQuestion => _currentIndex == total - 1;
  bool get canGoPrevious => _currentIndex > 0;

  int get correctCount => _selections.entries
      .where((e) => questions[e.key].correctIndex == e.value)
      .length;

  int get incorrectCount => _selections.length - correctCount;
  int get unansweredCount => total - _selections.length;

  // --- Mutations ---

  /// Selects an option for the current question.
  ///
  /// Practice modes and the full exam lock immediately (immediate feedback,
  /// no change after seeing the answer). Deferred modes (timed/mock) allow
  /// changing until finish.
  /// Returns true if the selection was applied.
  bool selectOption(int optionIndex) {
    if (_finished) return false;
    if (optionIndex < 0 || optionIndex >= current.options.length) return false;
    if (isCurrentLocked) return false;
    _selections[_currentIndex] = optionIndex;
    _recordTime();
    if (immediateFeedback) _locked.add(_currentIndex);
    return true;
  }

  void _recordTime() {
    final elapsed =
        _clock().difference(_questionShownAt).inMilliseconds;
    _timeMs[_currentIndex] =
        (_timeMs[_currentIndex] ?? 0) + (elapsed < 0 ? 0 : elapsed);
    _questionShownAt = _clock();
  }

  void goTo(int index) {
    if (_finished || index < 0 || index >= total) return;
    _currentIndex = index;
    _questionShownAt = _clock();
  }

  void next() => goTo(_currentIndex + 1);
  void previous() => goTo(_currentIndex - 1);

  /// Finalizes the session into a persistable [QuizOutcome].
  QuizOutcome finish({required int elapsedSeconds}) {
    _finished = true;
    final attempts = <QuestionAttempt>[];
    for (var i = 0; i < total; i++) {
      final selected = _selections[i] ?? -1;
      attempts.add(QuestionAttempt(
        questionId: questions[i].id,
        chapterId: questions[i].chapterId,
        topicId: questions[i].topicId,
        selectedIndex: selected,
        isCorrect: selected == questions[i].correctIndex,
        timeMs: _timeMs[i] ?? 0,
      ));
    }
    final result = QuizResult(
      mode: mode,
      chapterId: chapterId,
      total: total,
      correct: correctCount,
      incorrect: incorrectCount,
      unanswered: unansweredCount,
      timeSeconds: elapsedSeconds,
      takenAt: _clock(),
    );
    return QuizOutcome(
        result: result,
        attempts: attempts,
        questions: questions,
        marks: marks);
  }

  /// Resets all answers and returns to the first question.
  void restart() {
    _selections.clear();
    _locked.clear();
    _timeMs.clear();
    _currentIndex = 0;
    _finished = false;
    _questionShownAt = _clock();
  }
}
