import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// SQLite access for user-generated data and durable remote-content caching.
class DatabaseHelper {
  DatabaseHelper({this.overridePath});

  /// Test hook: pass `inMemoryDatabasePath` (with sqflite_common_ffi) in tests.
  final String? overridePath;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path =
        overridePath ?? p.join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE content_cache(
              cache_key TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              fetched_at INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE practice_progress(
              question_id TEXT PRIMARY KEY,
              is_correct INTEGER NOT NULL,
              answered_at INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS content_cache_chunks');
          await db.execute('DELETE FROM content_cache');
          await db.execute('''
            CREATE TABLE content_cache_chunks(
              cache_key TEXT NOT NULL,
              chunk_index INTEGER NOT NULL,
              payload TEXT NOT NULL,
              fetched_at INTEGER NOT NULL,
              PRIMARY KEY(cache_key, chunk_index)
            )
          ''');
        }
      },
      // Tests reuse the in-memory path across instances; sqflite's global
      // single-instance cache would hand a stale connection to later tests.
      singleInstance: overridePath == null,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quiz_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        chapter_id TEXT,
        total INTEGER NOT NULL,
        correct INTEGER NOT NULL,
        incorrect INTEGER NOT NULL,
        unanswered INTEGER NOT NULL,
        time_seconds INTEGER NOT NULL,
        taken_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE question_attempts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result_id INTEGER NOT NULL REFERENCES quiz_results(id) ON DELETE CASCADE,
        question_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        selected_index INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        time_ms INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_type TEXT NOT NULL,
        item_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(item_type, item_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE flashcard_reviews(
        card_id TEXT PRIMARY KEY,
        ease REAL NOT NULL,
        interval_days INTEGER NOT NULL,
        due_date INTEGER NOT NULL,
        review_count INTEGER NOT NULL,
        last_reviewed_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE topic_progress(
        topic_id TEXT PRIMARY KEY,
        completed INTEGER NOT NULL DEFAULT 0,
        completion_pct REAL NOT NULL DEFAULT 0,
        last_studied_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE content_cache(
        cache_key TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        fetched_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE content_cache_chunks(
        cache_key TEXT NOT NULL,
        chunk_index INTEGER NOT NULL,
        payload TEXT NOT NULL,
        fetched_at INTEGER NOT NULL,
        PRIMARY KEY(cache_key, chunk_index)
      )
    ''');
    await db.execute('''
      CREATE TABLE practice_progress(
        question_id TEXT PRIMARY KEY,
        is_correct INTEGER NOT NULL,
        answered_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_attempts_topic ON question_attempts(topic_id)',
    );
    await db.execute(
      'CREATE INDEX idx_attempts_result ON question_attempts(result_id)',
    );
  }

  Future<void> close() async {
    try {
      await _db?.close();
    } catch (e) {
      debugPrint('DatabaseHelper.close: $e');
    }
    _db = null;
  }
}
