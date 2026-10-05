import 'dart:convert';
import 'dart:io';

import 'package:exam_prep_pro/core/services/content_source.dart';

/// Serves study content from JSON in place of Supabase.
///
/// [FixtureContentBackend.snapshot] reads `test/fixtures/content/*.json`, a
/// copy of the Supabase content written by
/// `node tools/export_supabase_assets.js`. Files are read synchronously:
/// async I/O never completes under the widget tests' fake-async clock.
class FixtureContentBackend implements ContentBackend {
  /// Content given per file name (`chapters.json`, `topics.json`, …); a
  /// missing file is an empty table. Rows are JSON round-tripped so they
  /// arrive typed as a network response would.
  FixtureContentBackend(Map<String, Object> files)
    : _files = {
        for (final e in files.entries)
          e.key: (jsonDecode(jsonEncode(e.value)) as List)
              .cast<Map<String, dynamic>>(),
      };

  FixtureContentBackend.snapshot() : _files = null;

  final Map<String, List<Map<String, dynamic>>>? _files;

  /// Parsed once per test isolate: the snapshot is several megabytes.
  static final _snapshot = <String, List<Map<String, dynamic>>>{};

  Future<List<Map<String, dynamic>>> _rows(String file) async {
    final files = _files;
    if (files != null) return files[file] ?? const [];
    return _snapshot[file] ??= (jsonDecode(
      File('test/fixtures/content/$file').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> chapters() => _rows('chapters.json');

  @override
  Future<List<Map<String, dynamic>>> topics() => _rows('topics.json');

  @override
  Future<List<Map<String, dynamic>>> questions({
    String? chapterId,
    String? topicId,
  }) async {
    final rows = await _rows('questions.json');
    return rows
        .where(
          (row) =>
              (chapterId == null || row['chapter_id'] == chapterId) &&
              (topicId == null || row['topic_id'] == topicId),
        )
        .toList();
  }

  @override
  Future<int> questionCount({String? chapterId}) async => (await questions())
      .where((row) => chapterId == null || row['chapter_id'] == chapterId)
      .length;

  @override
  Future<List<Map<String, dynamic>>> questionCountsByChapter() async {
    final counts = <String, int>{};
    for (final row in await questions()) {
      final chapterId = row['chapter_id'];
      if (chapterId is String) {
        counts.update(chapterId, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return [
      for (final entry in counts.entries)
        {'chapter_id': entry.key, 'mcq_count': entry.value},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> theoryContent() => _rows('theory.json');

  @override
  Future<List<Map<String, dynamic>>> formulas({String? chapterId}) async {
    final rows = await _rows('formulas.json');
    return rows
        .where(
          (row) => chapterId == null || row['chapter_id'] == chapterId,
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> flashcards() => _rows('flashcards.json');
}

/// A backend that fails like Supabase does without a connection, until
/// [online] is set; then it serves [whenOnline].
class OfflineContentBackend implements ContentBackend {
  OfflineContentBackend(this.whenOnline);

  final ContentBackend whenOnline;
  bool online = false;
  int requests = 0;

  Future<List<Map<String, dynamic>>> _fetch(
    Future<List<Map<String, dynamic>>> Function() rows,
  ) async {
    requests++;
    if (!online) {
      throw const SocketException('Failed host lookup: supabase.co');
    }
    return rows();
  }

  @override
  Future<List<Map<String, dynamic>>> chapters() => _fetch(whenOnline.chapters);

  @override
  Future<List<Map<String, dynamic>>> topics() => _fetch(whenOnline.topics);

  @override
  Future<List<Map<String, dynamic>>> questions({
    String? chapterId,
    String? topicId,
  }) =>
      _fetch(() => whenOnline.questions(
            chapterId: chapterId,
            topicId: topicId,
          ));

  @override
  Future<int> questionCount({String? chapterId}) =>
      whenOnline.questionCount(chapterId: chapterId);

  @override
  Future<List<Map<String, dynamic>>> questionCountsByChapter() =>
      whenOnline.questionCountsByChapter();

  @override
  Future<List<Map<String, dynamic>>> theoryContent() =>
      _fetch(whenOnline.theoryContent);

  @override
  Future<List<Map<String, dynamic>>> formulas({String? chapterId}) =>
      _fetch(() => whenOnline.formulas(chapterId: chapterId));

  @override
  Future<List<Map<String, dynamic>>> flashcards() =>
      _fetch(whenOnline.flashcards);
}
