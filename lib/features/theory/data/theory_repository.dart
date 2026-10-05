import '../../../core/services/content_source.dart';
import '../domain/theory_content.dart';

abstract class TheoryRepository {
  Future<TheoryContent?> getContentForTopic(String topicId);
  Future<List<TheoryContent>> getAllContent();
}

class TheoryRepositoryImpl implements TheoryRepository {
  TheoryRepositoryImpl(this._source);

  final ContentSource _source;

  @override
  Future<TheoryContent?> getContentForTopic(String topicId) async =>
      (await _source.theory()).where((t) => t.topicId == topicId).firstOrNull;

  @override
  Future<List<TheoryContent>> getAllContent() => _source.theory();
}
