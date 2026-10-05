import 'package:flutter/foundation.dart';

import '../../features/chapters/domain/chapter.dart';
import '../../features/chapters/domain/topic.dart';
import '../../features/flashcards/domain/flashcard.dart';
import '../../features/formulas/domain/formula.dart';
import '../../features/quiz/domain/question.dart';
import '../../features/theory/domain/theory_content.dart';
import '../constants/app_strings.dart';

/// Where study content rows come from. The app ships no content of its own:
/// the one implementation is [SupabaseContentSource]; tests substitute
/// fixtures.
abstract interface class ContentBackend {
  Future<List<Map<String, dynamic>>> chapters();
  Future<List<Map<String, dynamic>>> topics();
  Future<List<Map<String, dynamic>>> questions({
    String? chapterId,
    String? topicId,
  });
  Future<int> questionCount({String? chapterId});
  Future<List<Map<String, dynamic>>> questionCountsByChapter();
  Future<List<Map<String, dynamic>>> theoryContent();
  Future<List<Map<String, dynamic>>> formulas({String? chapterId});
  Future<List<Map<String, dynamic>>> flashcards();
}

/// Content could not be fetched (offline, server error). Its text is what
/// the failing screen's error state shows.
class ContentUnavailableException implements Exception {
  const ContentUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => AppStrings.contentUnavailable;
}

/// Loads all study content from Supabase and keeps it in memory for the
/// session.
///
/// A failed fetch throws [ContentUnavailableException] and is not
/// remembered, so a retry fetches again. Parsing is defensive: malformed
/// rows are skipped (and logged in debug) — the app never crashes on
/// content.
class ContentSource {
  ContentSource(this._backend);

  final ContentBackend _backend;

  List<Chapter>? _chapters;
  List<Topic>? _topics;
  List<Question>? _questions;
  List<TheoryContent>? _theory;
  List<Formula>? _formulas;
  List<Flashcard>? _flashcards;

  void clearMemoryCache() {
    _chapters = null;
    _topics = null;
    _questions = null;
    _theory = null;
    _formulas = null;
    _flashcards = null;
  }

  Future<List<T>> _loadModels<T>(
    String table,
    Future<List<Map<String, dynamic>>> Function() fetch,
    T? Function(Map<String, dynamic>) parse,
  ) async {
    final List<Map<String, dynamic>> rows;
    try {
      rows = await fetch();
    } catch (e) {
      debugPrint('ContentSource: failed to load $table: $e');
      throw ContentUnavailableException(e);
    }
    final models = <T>[];
    var invalidCount = 0;
    for (final row in rows) {
      final map = _normalizeRow(row);
      try {
        final model = parse(map);
        if (model != null) {
          models.add(model);
        } else if (kDebugMode) {
          invalidCount++;
          if (invalidCount == 1) {
            debugPrint(
              'ContentSource: first invalid row in $table has keys: '
              '${map.keys.toList()}',
            );
          }
        }
      } catch (e) {
        debugPrint('ContentSource: bad entry in $table: $e');
      }
    }
    if (invalidCount > 0) {
      debugPrint(
        'ContentSource: skipped $invalidCount invalid entries in $table',
      );
    }
    return models;
  }

  Future<List<Chapter>> chapters() async {
    final result = _chapters ??= (await _loadModels(
      'chapters',
      _backend.chapters,
      Chapter.tryFromJson,
    ))..sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  /// Each collection is fetched once and filtered in memory: one Supabase
  /// request (and one cache entry) per table.
  Future<List<Topic>> topics({String? chapterId}) async {
    final all = _topics ??= (await _loadModels(
      'topics',
      _backend.topics,
      Topic.tryFromJson,
    ))..sort((a, b) => a.order.compareTo(b.order));
    if (chapterId == null) return all;
    return all.where((topic) => topic.chapterId == chapterId).toList();
  }

  Future<List<Question>> questions({String? chapterId, String? topicId}) async {
    if (chapterId == null && topicId == null) {
      return _questions ??= await _loadModels(
        'questions',
        // SupabaseContentSource.questions attaches the answer options.
        _backend.questions,
        Question.tryFromJson,
      );
    }
    return _loadModels(
      'questions',
      () => _backend.questions(chapterId: chapterId, topicId: topicId),
      Question.tryFromJson,
    );
  }

  Future<int> questionCount({String? chapterId}) async {
    if (chapterId == null) return (await questions()).length;
    return _backend.questionCount(chapterId: chapterId);
  }

  Future<List<Map<String, dynamic>>> questionCountsByChapter() =>
      _backend.questionCountsByChapter();

  Future<List<TheoryContent>> theory() async => _theory ??= await _loadModels(
    'theory_content',
    _backend.theoryContent,
    TheoryContent.tryFromJson,
  );

  Future<List<Formula>> formulas({String? chapterId}) async {
    if (chapterId == null) {
      return _formulas ??= await _loadModels(
        'formulas',
        _backend.formulas,
        Formula.tryFromJson,
      );
    }
    return _loadModels(
      'formulas',
      () => _backend.formulas(chapterId: chapterId),
      Formula.tryFromJson,
    );
  }

  Future<List<Flashcard>> flashcards() async =>
      _flashcards ??= await _loadModels(
        'flashcards',
        _backend.flashcards,
        Flashcard.tryFromJson,
      );

  /// Maps Supabase's snake_case columns onto the model's JSON keys.
  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    if (!normalized.containsKey('options')) {
      final optionKeys = ['a', 'b', 'c', 'd']
          .map((suffix) => 'option_$suffix')
          .where(normalized.containsKey)
          .toList();
      if (optionKeys.length >= 2) {
        normalized['options'] = optionKeys
            .map((key) => normalized[key].toString())
            .toList();
      }
    }
    const aliases = {
      'question_id': 'id',
      'chapter': 'chapterId',
      'chapter_id': 'chapterId',
      'topic': 'topicId',
      'topic_id': 'topicId',
      'parent_topic_id': 'parentTopicId',
      'question_text': 'questionText',
      'question': 'questionText',
      'question_body': 'questionText',
      'correct_index': 'correctIndex',
      'correct_answer_index': 'correctIndex',
      'correct_option_index': 'correctIndex',
      'correct_answer': 'correctAnswer',
      'answer_index': 'correctIndex',
      'code_snippet': 'codeSnippet',
      'code_language': 'codeLanguage',
      'has_formulas': 'hasFormulas',
      'has_notes': 'hasNotes',
      'plain_text': 'plainText',
      'is_code': 'isCode',
      'choices': 'options',
      'answer_options': 'options',
      'question_options': 'options',
      'explanation_text': 'explanation',
      'difficulty_level': 'difficulty',
    };
    for (final entry in aliases.entries) {
      if (!normalized.containsKey(entry.value) &&
          normalized.containsKey(entry.key)) {
        normalized[entry.value] = normalized[entry.key];
      }
    }
    // Topics carry their subtitle in `description`; imported rows repeat
    // the title there, which would show the same text twice on a card.
    final description = row['description'];
    if (!normalized.containsKey('subtitle') &&
        description is String &&
        description != row['title']) {
      normalized['subtitle'] = description;
    }
    return normalized;
  }
}
