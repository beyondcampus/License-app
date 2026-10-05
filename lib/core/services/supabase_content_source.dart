import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_cache.dart';
import 'content_source.dart';

/// Reads the study content from Supabase — the app's only content source —
/// through the durable local cache.
class SupabaseContentSource implements ContentBackend {
  SupabaseContentSource(this._client, this._cache);

  final SupabaseClient _client;
  final ContentCache _cache;

  /// Cache keys are namespaced by the Supabase project, so pointing the app
  /// at another project never serves content cached from the previous one.
  late final String _project = Uri.parse(_client.rest.url).host;

  String _key(String key) =>
      key.replaceFirst('supabase:', 'supabase:$_project:');

  /// Cached content older than this is re-fetched, so edits made in
  /// Supabase reach signed-in users without a sign-out. When the fetch fails
  /// (offline) the stale copy is still served.
  static const Duration maxAge = Duration(hours: 6);

  @override
  Future<List<Map<String, dynamic>>> chapters({bool forceRefresh = false}) =>
      _table('chapters', forceRefresh: forceRefresh);

  @override
  Future<List<Map<String, dynamic>>> topics({
    String? chapterId,
    bool forceRefresh = false,
  }) => _table(
    'topics',
    cacheKey: chapterId == null
        ? 'supabase:topics'
        : 'supabase:topics:chapter:$chapterId',
    filters: chapterId == null ? null : {'chapter_id': chapterId},
    forceRefresh: forceRefresh,
  );

  @override
  Future<List<Map<String, dynamic>>> theoryContent({
    bool forceRefresh = false,
  }) =>
      _table('theory_content', orderBy: 'topic_id', forceRefresh: forceRefresh);

  @override
  Future<List<Map<String, dynamic>>> questions({
    String? chapterId,
    String? topicId,
    bool forceRefresh = false,
  }) {
    final queryFilters = <String, String>{};
    if (chapterId != null) queryFilters['chapter_id'] = chapterId;
    if (topicId != null) queryFilters['topic_id'] = topicId;

    return _table(
      'questions',
      cacheKey: topicId != null
          ? 'supabase:questions:topic:$topicId'
          : chapterId != null
          ? 'supabase:questions:chapter:$chapterId'
          : 'supabase:questions',
      filters: queryFilters.isEmpty ? null : queryFilters,
      forceRefresh: forceRefresh,
    ).then(_attachQuestionOptions);
  }

  Future<int> questionCount({String? chapterId}) async {
    final key = _key(
      chapterId == null
          ? 'supabase:question_count'
          : 'supabase:question_count:chapter:$chapterId',
    );
    final cached = await _cache.getOrFetch(key, () async {
      if (kDebugMode) {
        debugPrint(
          'SUPABASE_REQUEST table=questions countOnly=true '
          'filters=${chapterId == null ? {} : {'chapter_id': chapterId}}',
        );
      }
      var query = _client.from('questions').count();
      if (chapterId != null) {
        query = query.eq('chapter_id', chapterId);
      }
      final count = await query;
      if (kDebugMode) {
        debugPrint('SUPABASE_RESPONSE table=questions count=$count');
      }
      return [
        {'count': count},
      ];
    }, maxAge: maxAge);
    return (cached.firstOrNull?['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<Map<String, dynamic>>> questionCountsByChapter() => _cache
      .getOrFetch(
        _key('supabase:chapter_question_counts'),
        () async {
          if (kDebugMode) {
            debugPrint(
              'SUPABASE_REQUEST view=chapter_question_counts select=*',
            );
          }
          final response = await _client
              .from('chapter_question_counts')
              .select('chapter_id, mcq_count')
              .order('chapter_id');
          final rows = response
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          if (kDebugMode) {
            debugPrint(
              'SUPABASE_RESPONSE view=chapter_question_counts '
              'rows=${rows.length} payload=${jsonEncode(rows)}',
            );
          }
          return rows;
        },
        maxAge: maxAge,
      );

  Future<List<Map<String, dynamic>>> questionOptions({
    bool forceRefresh = false,
  }) => _table('question_options', forceRefresh: forceRefresh);

  @override
  Future<List<Map<String, dynamic>>> formulas({
    String? chapterId,
    bool forceRefresh = false,
  }) =>
      _table(
        'formulas',
        cacheKey: chapterId == null
            ? 'supabase:formulas'
            : 'supabase:formulas:chapter:$chapterId',
        filters: chapterId == null ? null : {'chapter_id': chapterId},
        forceRefresh: forceRefresh,
      );

  @override
  Future<List<Map<String, dynamic>>> flashcards({bool forceRefresh = false}) =>
      _table('flashcards', forceRefresh: forceRefresh);

  Future<List<Map<String, dynamic>>> _table(
    String table, {
    String? cacheKey,
    Map<String, String>? filters,
    String select = '*',
    String orderBy = 'id',
    required bool forceRefresh,
  }) {
    return _cache.getOrFetch(
      _key(cacheKey ?? 'supabase:$table'),
      () async {
        const pageSize = 100;
        final allRows = <Map<String, dynamic>>[];
        var offset = 0;

        while (true) {
          if (kDebugMode) {
            debugPrint(
              'SUPABASE_REQUEST table=$table select=$select '
              'filters=${filters ?? {}} range=$offset-${offset + pageSize - 1}',
            );
          }
          var query = _client.from(table).select(select);
          if (filters != null) {
            for (final filter in filters.entries) {
              query = query.eq(filter.key, filter.value);
            }
          }
          // A stable order is required for paging: without it pages of a large
          // table can overlap or skip rows.
          final page = await query
              .order(orderBy, ascending: true)
              .range(offset, offset + pageSize - 1);
          final responseRows = page
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          allRows.addAll(responseRows);
          if (kDebugMode) {
            debugPrint(
              'SUPABASE_RESPONSE table=$table rows=${responseRows.length} '
              'payload=${jsonEncode(responseRows)}',
            );
          }
          if (page.length < pageSize) break;
          offset += pageSize;
        }

        return allRows;
      },
      maxAge: maxAge,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<Map<String, dynamic>>> _attachQuestionOptions(
    List<Map<String, dynamic>> questions,
  ) async {
    final missing = questions
        .where((question) => question['options'] == null)
        .map((question) => question['id'])
        .whereType<String>()
        .toSet();
    if (missing.isEmpty) return questions;

    final ids = missing.toList()..sort();
    final optionRows = await _cache.getOrFetch(
      _key('supabase:question_options:${ids.join(',')}'),
      () async {
        final rows = <Map<String, dynamic>>[];
        for (var start = 0; start < ids.length; start += 100) {
          final end = (start + 100 < ids.length) ? start + 100 : ids.length;
          if (kDebugMode) {
            debugPrint(
              'SUPABASE_REQUEST table=question_options '
              'questionIds=${ids.sublist(start, end)}',
            );
          }
          final page = await _client
              .from('question_options')
              .select()
              .inFilter('question_id', ids.sublist(start, end));
          final responseRows = page
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          rows.addAll(responseRows);
          if (kDebugMode) {
            debugPrint(
              'SUPABASE_RESPONSE table=question_options '
              'rows=${responseRows.length} payload=${jsonEncode(responseRows)}',
            );
          }
        }
        return rows;
      },
      maxAge: maxAge,
    );

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in optionRows) {
      final questionId = row['question_id'] ?? row['questionId'];
      if (questionId is String) {
        grouped.putIfAbsent(questionId, () => []).add(row);
      }
    }
    for (final options in grouped.values) {
      options.sort((a, b) => _optionOrder(a).compareTo(_optionOrder(b)));
    }

    return questions.map((question) {
      final id = question['id'];
      final options = id is String ? grouped[id] : null;
      if (options == null || options.isEmpty) return question;
      return {
        ...question,
        'options': options.map(_optionText).whereType<String>().toList(),
      };
    }).toList();
  }

  int _optionOrder(Map<String, dynamic> row) {
    final value = row['option_index'] ?? row['optionIndex'] ?? row['order'];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }

  String? _optionText(Map<String, dynamic> row) {
    final value =
        row['option_text'] ??
        row['optionText'] ??
        row['text'] ??
        row['value'] ??
        row['label'];
    return value?.toString();
  }
}
