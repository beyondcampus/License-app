import 'package:flutter/foundation.dart';

import '../../bookmarks/data/bookmark_repository.dart';
import '../../bookmarks/domain/bookmark.dart';
import '../../chapters/data/progress_repository.dart';
import '../data/theory_repository.dart';
import '../domain/theory_content.dart';

/// Screen-scoped state for the theory reader: content, bookmark state and
/// completion for one topic.
class TheoryProvider extends ChangeNotifier {
  TheoryProvider({
    required this.topicId,
    required this._theory,
    required this._bookmarks,
    required this._progress,
  });

  final String topicId;
  final TheoryRepository _theory;
  final BookmarkRepository _bookmarks;
  final ProgressRepository _progress;

  bool loading = true;
  String? error;
  TheoryContent? content;
  bool isBookmarked = false;
  bool isCompleted = false;
  int tabIndex = 0;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      content = await _theory.getContentForTopic(topicId);
      isBookmarked =
          await _bookmarks.isBookmarked(BookmarkType.topic, topicId);
      isCompleted = (await _progress.getTopicProgress(topicId))?.completed ??
          false;
      // Opening a topic counts as studying it (drives streak + readiness).
      await _progress.recordTopicStudied(topicId);
      error = null;
    } catch (e) {
      debugPrint('TheoryProvider.load: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  void setTab(int index) {
    if (index == tabIndex) return;
    tabIndex = index;
    notifyListeners();
  }

  Future<void> toggleBookmark() async {
    isBookmarked = await _bookmarks.toggle(BookmarkType.topic, topicId);
    notifyListeners();
  }

  Future<void> toggleCompleted() async {
    isCompleted = !isCompleted;
    await _progress.setTopicCompleted(topicId, isCompleted);
    notifyListeners();
  }
}
