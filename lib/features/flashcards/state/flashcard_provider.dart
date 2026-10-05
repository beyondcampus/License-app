import 'package:flutter/foundation.dart';

import '../data/flashcard_repository.dart';
import '../domain/flashcard.dart';

/// Drives the flashcard review session on the Cards tab: due queue,
/// flip state and grading with persisted spaced repetition.
class FlashcardProvider extends ChangeNotifier {
  FlashcardProvider(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final FlashcardRepository _repository;
  final DateTime Function() _clock;

  bool loading = false;
  bool loaded = false;
  String? error;

  List<DueCard> _queue = [];
  int _position = 0;
  bool isFlipped = false;
  int sessionTotal = 0;

  DueCard? get current =>
      _position < _queue.length ? _queue[_position] : null;

  /// 1-based position shown in the app bar ("5 / 30").
  int get positionLabel =>
      _queue.isEmpty ? 0 : (_position + 1).clamp(1, sessionTotal);

  int get dueCount => _queue.length - _position;
  bool get sessionDone => loaded && current == null;

  /// Preview interval labels for the grade buttons.
  String intervalLabel(ReviewGrade grade) {
    final review = current?.review;
    if (review == null) return '';
    final days = review.previewIntervalDays(grade);
    if (days >= 30) {
      final months = (days / 30).round();
      return '($months ${months == 1 ? 'month' : 'months'})';
    }
    return '($days ${days == 1 ? 'day' : 'days'})';
  }

  Future<void> load() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      _queue = await _repository.getDueCards(_clock());
      _position = 0;
      sessionTotal = _queue.length;
      isFlipped = false;
      error = null;
    } catch (e) {
      debugPrint('FlashcardProvider.load: $e');
      error = e.toString();
    }
    loading = false;
    loaded = true;
    notifyListeners();
  }

  void flip() {
    if (current == null) return;
    isFlipped = !isFlipped;
    notifyListeners();
  }

  /// Grades the current card, persists the new review state and advances.
  Future<void> grade(ReviewGrade grade) async {
    final card = current;
    if (card == null) return;
    try {
      await _repository.saveReview(card.review.graded(grade, _clock()));
    } catch (e) {
      debugPrint('FlashcardProvider.grade: $e');
    }
    _position++;
    isFlipped = false;
    notifyListeners();
  }
}
