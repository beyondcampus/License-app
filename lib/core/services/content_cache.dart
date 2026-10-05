import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'database_helper.dart';

/// Durable cache for content fetched from Supabase.
///
/// The cache stores complete collection payloads. This keeps the remote
/// repositories simple and allows the app to reuse content after a restart.
class ContentCache {
  ContentCache(this._dbHelper);

  static const _chunkSize = 100 * 1024;

  final DatabaseHelper _dbHelper;
  final _inFlight = <String, Future<List<Map<String, dynamic>>>>{};
  int _generation = 0;

  Future<List<Map<String, dynamic>>> getOrFetch(
    String key,
    Future<List<Map<String, dynamic>>> Function() fetch, {
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final request = _fetchAndCache(
      key,
      fetch,
      maxAge: maxAge,
      forceRefresh: forceRefresh,
    );
    _inFlight[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight[key], request)) {
        _inFlight.remove(key);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAndCache(
    String key,
    Future<List<Map<String, dynamic>>> Function() fetch, {
    Duration? maxAge,
    required bool forceRefresh,
  }) async {
    if (!forceRefresh) {
      final cached = await _read(key, maxAge: maxAge);
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('CONTENT_CACHE_HIT key=$key rows=${cached.length}');
        }
        return cached;
      }
    }
    if (kDebugMode) {
      debugPrint('CONTENT_CACHE_MISS key=$key forceRefresh=$forceRefresh');
    }
    final generation = _generation;
    final List<Map<String, dynamic>> fresh;
    try {
      fresh = await fetch();
    } catch (_) {
      // Offline or server error: serve an expired copy rather than nothing.
      final stale = await _read(key);
      if (stale != null) return stale;
      rethrow;
    }
    if (generation != _generation) return fresh;
    await _write(key, fresh);
    return fresh;
  }

  Future<void> invalidate([String? key]) async {
    _generation++;
    if (key == null) {
      _inFlight.clear();
    } else {
      _inFlight.remove(key);
    }
    final db = await _dbHelper.database;
    if (key == null) {
      await db.delete('content_cache');
      await db.delete('content_cache_chunks');
    } else {
      await db.delete(
        'content_cache',
        where: 'cache_key = ?',
        whereArgs: [key],
      );
      await db.delete(
        'content_cache_chunks',
        where: 'cache_key = ?',
        whereArgs: [key],
      );
    }
  }

  Future<List<Map<String, dynamic>>?> _read(
    String key, {
    Duration? maxAge,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'content_cache_chunks',
      columns: ['chunk_index', 'payload', 'fetched_at'],
      where: 'cache_key = ?',
      whereArgs: [key],
      orderBy: 'chunk_index ASC',
    );
    if (rows.isEmpty) return null;

    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(
      (rows.first['fetched_at'] as num).toInt(),
    );
    if (maxAge != null && DateTime.now().difference(fetchedAt) > maxAge) {
      return null;
    }

    try {
      final payload = rows.map((row) => row['payload'] as String).join();
      final decoded = jsonDecode(payload);
      if (decoded is! List) return null;
      return decoded.whereType<Map<String, dynamic>>().toList();
    } on FormatException {
      await invalidate(key);
      return null;
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> payload) async {
    final db = await _dbHelper.database;
    final encoded = jsonEncode(payload);
    final fetchedAt = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.delete(
        'content_cache_chunks',
        where: 'cache_key = ?',
        whereArgs: [key],
      );
      for (var start = 0, index = 0;
          start < encoded.length;
          start += _chunkSize, index++) {
        final end = (start + _chunkSize < encoded.length)
            ? start + _chunkSize
            : encoded.length;
        await txn.insert('content_cache_chunks', {
          'cache_key': key,
          'chunk_index': index,
          'payload': encoded.substring(start, end),
          'fetched_at': fetchedAt,
        });
      }
    });
  }
}
