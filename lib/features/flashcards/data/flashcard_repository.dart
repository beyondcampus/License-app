import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../core/services/content_source.dart';
import '../../../core/services/database_helper.dart';
import '../domain/flashcard.dart';

/// A flashcard paired with its (possibly fresh) review state.
class DueCard {
  const DueCard(this.card, this.review);
  final Flashcard card;
  final FlashcardReview review;
}

abstract class FlashcardRepository {
  Future<List<Flashcard>> getAllCards();

  /// Cards due for review at [now]: never-reviewed cards first, then by due date.
  Future<List<DueCard>> getDueCards(DateTime now);

  Future<FlashcardReview?> getReview(String cardId);
  Future<void> saveReview(FlashcardReview review);
  Future<int> dueCount(DateTime now);
}

class FlashcardRepositoryImpl implements FlashcardRepository {
  FlashcardRepositoryImpl(this._source, this._dbHelper);

  final ContentSource _source;
  final DatabaseHelper _dbHelper;

  @override
  Future<List<Flashcard>> getAllCards() => _source.flashcards();

  Future<Map<String, FlashcardReview>> _allReviews() async {
    final db = await _dbHelper.database;
    final rows = await db.query('flashcard_reviews');
    return {
      for (final row in rows)
        row['card_id'] as String: FlashcardReview.fromDbMap(row),
    };
  }

  @override
  Future<List<DueCard>> getDueCards(DateTime now) async {
    final cards = await getAllCards();
    final reviews = await _allReviews();
    final due = <DueCard>[];
    for (final card in cards) {
      final review = reviews[card.id] ?? FlashcardReview.fresh(card.id, now);
      if (review.isDue(now)) due.add(DueCard(card, review));
    }
    due.sort((a, b) {
      final aNew = a.review.reviewCount == 0 ? 0 : 1;
      final bNew = b.review.reviewCount == 0 ? 0 : 1;
      if (aNew != bNew) return aNew - bNew;
      return a.review.dueDate.compareTo(b.review.dueDate);
    });
    return due;
  }

  @override
  Future<FlashcardReview?> getReview(String cardId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('flashcard_reviews',
        where: 'card_id = ?', whereArgs: [cardId], limit: 1);
    if (rows.isEmpty) return null;
    return FlashcardReview.fromDbMap(rows.first);
  }

  @override
  Future<void> saveReview(FlashcardReview review) async {
    final db = await _dbHelper.database;
    await db.insert('flashcard_reviews', review.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<int> dueCount(DateTime now) async =>
      (await getDueCards(now)).length;
}
