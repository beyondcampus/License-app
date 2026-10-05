import 'package:flutter/foundation.dart';

import '../../chapters/domain/chapter.dart';
import '../../chapters/domain/topic.dart';
import 'quiz_result.dart';

/// Describes the quiz to run — passed as the argument of the `/quiz` route.
@immutable
class QuizConfig {
  const QuizConfig({
    required this.mode,
    this.chapterId,
    this.topicId,
    this.topicIds,
    this.title = 'Quiz',
    this.questionCount,
    this.timed = false,
    this.skipCorrect = false,
  });

  final QuizMode mode;

  /// Restrict to one chapter (null = all chapters).
  final String? chapterId;

  /// Restrict to one topic (null = whole chapter/mixed).
  final String? topicId;

  /// Restrict to a set of topics: a parent topic practises all its
  /// subtopics together. Takes precedence over [topicId].
  final List<String>? topicIds;

  /// Shown in the quiz app bar.
  final String title;

  /// Null = use every available question (capped by AppConstants).
  final int? questionCount;

  /// Countdown enabled (Timed Test and Full Exam only).
  final bool timed;

  /// Topic practice: leave out the questions whose latest Practice answer is
  /// correct, keeping the rest in their normal order.
  final bool skipCorrect;

  factory QuizConfig.topicPractice(Topic topic) => QuizConfig(
        mode: QuizMode.practice,
        chapterId: topic.chapterId,
        topicId: topic.id,
        title: topic.title,
        skipCorrect: true,
      );

  factory QuizConfig.subtopicsPractice(Topic parent, List<Topic> subtopics) =>
      QuizConfig(
        mode: QuizMode.practice,
        chapterId: parent.chapterId,
        topicIds: [for (final t in subtopics) t.id],
        title: parent.title,
        skipCorrect: true,
      );

  factory QuizConfig.chapterPractice(Chapter chapter) => QuizConfig(
        mode: QuizMode.practice,
        chapterId: chapter.id,
        title: chapter.title,
      );

  factory QuizConfig.timedTest(Chapter chapter, int count) => QuizConfig(
        mode: QuizMode.timed,
        chapterId: chapter.id,
        title: chapter.title,
        questionCount: count,
        timed: true,
      );

  factory QuizConfig.mockExam(int count) => QuizConfig(
        mode: QuizMode.mock,
        title: 'Mock Exam',
        questionCount: count,
      );

  /// Full-length paper in the exam-hall pattern (see FullExamPaper).
  factory QuizConfig.fullExam() => const QuizConfig(
        mode: QuizMode.fullExam,
        title: 'Full Exam',
        timed: true,
      );

  factory QuizConfig.bookmarked() => const QuizConfig(
        mode: QuizMode.bookmarked,
        title: 'Bookmarked Questions',
      );
}
