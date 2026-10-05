import '../../../core/services/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/bookmark.dart';

abstract class BookmarkRepository {
  Future<List<Bookmark>> getAll();
  Future<List<Bookmark>> getByType(BookmarkType type);
  Future<bool> isBookmarked(BookmarkType type, String itemId);
  Future<void> add(BookmarkType type, String itemId);
  Future<void> remove(BookmarkType type, String itemId);

  /// Returns the new state (true = now bookmarked).
  Future<bool> toggle(BookmarkType type, String itemId);
}

class BookmarkRepositoryImpl implements BookmarkRepository {
  BookmarkRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  @override
  Future<List<Bookmark>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('bookmarks', orderBy: 'created_at DESC');
    return rows.map(Bookmark.fromDbMap).whereType<Bookmark>().toList();
  }

  @override
  Future<List<Bookmark>> getByType(BookmarkType type) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bookmarks',
        where: 'item_type = ?',
        whereArgs: [type.name],
        orderBy: 'created_at DESC');
    return rows.map(Bookmark.fromDbMap).whereType<Bookmark>().toList();
  }

  @override
  Future<bool> isBookmarked(BookmarkType type, String itemId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bookmarks',
        where: 'item_type = ? AND item_id = ?',
        whereArgs: [type.name, itemId],
        limit: 1);
    return rows.isNotEmpty;
  }

  @override
  Future<void> add(BookmarkType type, String itemId) async {
    final db = await _dbHelper.database;
    // UNIQUE(item_type, item_id) + IGNORE makes duplicates a no-op.
    await db.rawInsert(
      'INSERT OR IGNORE INTO bookmarks(item_type, item_id, created_at) '
      'VALUES(?, ?, ?)',
      [type.name, itemId, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> remove(BookmarkType type, String itemId) async {
    final db = await _dbHelper.database;
    await db.delete('bookmarks',
        where: 'item_type = ? AND item_id = ?',
        whereArgs: [type.name, itemId]);
  }

  @override
  Future<bool> toggle(BookmarkType type, String itemId) async {
    if (await isBookmarked(type, itemId)) {
      await remove(type, itemId);
      return false;
    }
    await add(type, itemId);
    return true;
  }
}

class SupabaseBookmarkRepository implements BookmarkRepository {
  SupabaseBookmarkRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser?.id ??
      (throw StateError('A signed-in user is required'));

  @override
  Future<List<Bookmark>> getAll() async {
    final rows = await _client
        .from('bookmarks')
        .select('item_type, item_id, created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(_fromRow).whereType<Bookmark>().toList();
  }

  @override
  Future<List<Bookmark>> getByType(BookmarkType type) async {
    final rows = await _client
        .from('bookmarks')
        .select('item_type, item_id, created_at')
        .eq('user_id', _userId)
        .eq('item_type', type.name)
        .order('created_at', ascending: false);
    return rows.map(_fromRow).whereType<Bookmark>().toList();
  }

  @override
  Future<bool> isBookmarked(BookmarkType type, String itemId) async {
    final rows = await _client
        .from('bookmarks')
        .select('item_id')
        .eq('user_id', _userId)
        .eq('item_type', type.name)
        .eq('item_id', itemId)
        .limit(1);
    return rows.isNotEmpty;
  }

  @override
  Future<void> add(BookmarkType type, String itemId) async {
    await _client.from('bookmarks').upsert({
      'user_id': _userId,
      'item_type': type.name,
      'item_id': itemId,
    }, onConflict: 'user_id,item_type,item_id');
  }

  @override
  Future<void> remove(BookmarkType type, String itemId) async {
    await _client
        .from('bookmarks')
        .delete()
        .eq('user_id', _userId)
        .eq('item_type', type.name)
        .eq('item_id', itemId);
  }

  @override
  Future<bool> toggle(BookmarkType type, String itemId) async {
    if (await isBookmarked(type, itemId)) {
      await remove(type, itemId);
      return false;
    }
    await add(type, itemId);
    return true;
  }

  Bookmark? _fromRow(Map<String, dynamic> row) {
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');
    if (createdAt == null) return null;
    return Bookmark(
      type: BookmarkType.values
              .where((type) => type.name == row['item_type'])
              .firstOrNull ??
          BookmarkType.topic,
      itemId: row['item_id'] as String,
      createdAt: createdAt.toLocal(),
    );
  }
}
