import 'package:flutter/foundation.dart';

import '../../../core/services/content_source.dart';
import '../../chapters/domain/chapter.dart';
import '../../chapters/domain/topic.dart';
import '../../formulas/domain/formula.dart';
import '../../quiz/domain/question.dart';

/// Grouped search results across all study content.
class SearchResults {
  const SearchResults({
    this.chapters = const [],
    this.topics = const [],
    this.formulas = const [],
    this.questions = const [],
  });

  final List<Chapter> chapters;
  final List<Topic> topics;
  final List<Formula> formulas;
  final List<Question> questions;

  bool get isEmpty =>
      chapters.isEmpty && topics.isEmpty && formulas.isEmpty &&
      questions.isEmpty;

  int get totalCount =>
      chapters.length + topics.length + formulas.length + questions.length;
}

/// In-memory search over the chapters, topics, theory, formulas and
/// questions loaded from Supabase. Theory matches surface as their owning
/// topic.
class SearchProvider extends ChangeNotifier {
  SearchProvider(this._source);

  final ContentSource _source;

  static const int maxPerGroup = 10;

  String query = '';
  bool searching = false;
  String? error;
  SearchResults results = const SearchResults();

  Future<void> search(String input) async {
    query = input;
    final q = input.trim().toLowerCase();
    error = null;
    if (q.isEmpty) {
      results = const SearchResults();
      notifyListeners();
      return;
    }
    searching = true;
    notifyListeners();
    try {
      final chapters = (await _source.chapters())
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q))
          .take(maxPerGroup)
          .toList();

      final allTopics = await _source.topics();
      final directTopicIds = <String>{};
      final topics = <Topic>[];
      for (final topic in allTopics) {
        if (topic.title.toLowerCase().contains(q) ||
            topic.subtitle.toLowerCase().contains(q)) {
          topics.add(topic);
          directTopicIds.add(topic.id);
        }
      }

      // Theory content matches roll up into their owning topic.
      final theory = await _source.theory();
      final topicById = {for (final t in allTopics) t.id: t};
      for (final content in theory) {
        if (directTopicIds.contains(content.topicId)) continue;
        final haystack = [
          ...content.concepts,
          ...content.formulas,
          ...content.notes,
        ].expand((b) => [b.text, ...b.items, b.plainText ?? '']).join(' ');
        if (haystack.toLowerCase().contains(q)) {
          final topic = topicById[content.topicId];
          if (topic != null) {
            topics.add(topic);
            directTopicIds.add(topic.id);
          }
        }
      }

      final formulas = (await _source.formulas())
          .where((f) =>
              f.title.toLowerCase().contains(q) ||
              f.plainText.toLowerCase().contains(q) ||
              f.description.toLowerCase().contains(q))
          .take(maxPerGroup)
          .toList();

      final questions = (await _source.questions())
          .where((question) =>
              question.questionText.toLowerCase().contains(q) ||
              question.explanation.toLowerCase().contains(q))
          .take(maxPerGroup)
          .toList();

      results = SearchResults(
        chapters: chapters,
        topics: topics.take(maxPerGroup).toList(),
        formulas: formulas,
        questions: questions,
      );
    } catch (e) {
      debugPrint('SearchProvider.search: $e');
      error = e.toString();
      results = const SearchResults();
    }
    searching = false;
    notifyListeners();
  }
}
