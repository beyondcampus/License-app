import 'package:exam_prep_pro/features/quiz/domain/question.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_result.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_session.dart';
import 'package:flutter_test/flutter_test.dart';

List<Question> _questions(int n) => [
      for (var i = 0; i < n; i++)
        Question(
          id: 'q$i',
          chapterId: 'ch1',
          topicId: i.isEven ? 'topicA' : 'topicB',
          questionText: 'Question $i',
          options: const ['a', 'b', 'c', 'd'],
          correctIndex: i % 4,
          explanation: 'because',
          difficulty: Difficulty.easy,
        ),
    ];

void main() {
  group('practice mode (immediate feedback)', () {
    test('selection locks immediately and cannot be changed', () {
      final s = QuizSession(questions: _questions(3), mode: QuizMode.practice);
      expect(s.selectOption(0), isTrue); // q0 correct is 0
      expect(s.isCurrentLocked, isTrue);
      expect(s.isCurrentCorrect, isTrue);
      // Attempting to change is rejected.
      expect(s.selectOption(2), isFalse);
      expect(s.currentSelection, 0);
    });

    test('scoring across questions', () {
      final s = QuizSession(questions: _questions(4), mode: QuizMode.practice);
      s.selectOption(0); // q0 correct (0)
      s.next();
      s.selectOption(0); // q1 wrong (correct 1)
      s.next();
      s.selectOption(2); // q2 correct (2)
      // q3 left unanswered.
      expect(s.correctCount, 2);
      expect(s.incorrectCount, 1);
      expect(s.unansweredCount, 1);
    });

    test('finish builds a full outcome with unanswered attempts', () {
      final s = QuizSession(questions: _questions(3), mode: QuizMode.practice);
      s.selectOption(0);
      final outcome = s.finish(elapsedSeconds: 61);
      expect(outcome.result.total, 3);
      expect(outcome.result.correct, 1);
      expect(outcome.result.unanswered, 2);
      expect(outcome.result.timeSeconds, 61);
      expect(outcome.attempts.length, 3);
      expect(outcome.attempts[1].selectedIndex, -1);
      expect(outcome.attempts[1].isCorrect, isFalse);
      // No further mutations after finish.
      expect(s.selectOption(1), isFalse);
    });
  });

  group('timed/mock mode (deferred feedback)', () {
    test('answers stay changeable until finish', () {
      final s = QuizSession(questions: _questions(3), mode: QuizMode.timed);
      expect(s.immediateFeedback, isFalse);
      s.selectOption(3);
      expect(s.isCurrentLocked, isFalse);
      s.selectOption(0); // change allowed
      expect(s.currentSelection, 0);
      expect(s.correctCount, 1);
    });

    test('navigation preserves selections', () {
      final s = QuizSession(questions: _questions(3), mode: QuizMode.mock);
      s.selectOption(1);
      s.next();
      s.selectOption(2);
      s.previous();
      expect(s.currentSelection, 1);
      expect(s.canGoPrevious, isFalse);
      s.goTo(2);
      expect(s.currentSelection, isNull);
      expect(s.isLastQuestion, isTrue);
    });
  });

  group('timing and restart', () {
    test('per-question time is measured with the injected clock', () {
      var now = DateTime(2026, 1, 1, 10, 0, 0);
      final s = QuizSession(
        questions: _questions(2),
        mode: QuizMode.practice,
        clock: () => now,
      );
      now = now.add(const Duration(seconds: 9));
      s.selectOption(0);
      s.next();
      now = now.add(const Duration(seconds: 20));
      s.selectOption(1);
      final outcome = s.finish(elapsedSeconds: 29);
      expect(outcome.attempts[0].timeMs, 9000);
      expect(outcome.attempts[1].timeMs, 20000);
    });

    test('restart clears all state', () {
      final s = QuizSession(questions: _questions(3), mode: QuizMode.practice);
      s.selectOption(0);
      s.next();
      s.selectOption(1);
      s.finish(elapsedSeconds: 10);
      s.restart();
      expect(s.currentIndex, 0);
      expect(s.answeredCount, 0);
      expect(s.isFinished, isFalse);
      expect(s.isCurrentLocked, isFalse);
      expect(s.selectOption(2), isTrue);
    });

    test('invalid option indices are rejected', () {
      final s = QuizSession(questions: _questions(1), mode: QuizMode.practice);
      expect(s.selectOption(-1), isFalse);
      expect(s.selectOption(4), isFalse);
      expect(s.answeredCount, 0);
    });
  });
}
