import 'package:flutter/foundation.dart';

import '../../../core/utils/validators.dart';

/// Rich-content block types supported by the theory reader.
enum TheoryBlockType {
  heading,
  paragraph,
  bulletList,
  formula,
  code,
  table,
  note,
  warning,
  examTip,
}

@immutable
class TheoryBlock {
  const TheoryBlock({
    required this.type,
    this.text = '',
    this.items = const [],
    this.latex,
    this.plainText,
    this.language,
    this.rows = const [],
  });

  final TheoryBlockType type;

  /// Main text (heading text, paragraph body, code source, note body...).
  final String text;

  /// Bullet list items.
  final List<String> items;

  /// LaTeX source for formula blocks.
  final String? latex;

  /// Plain-text fallback for formula blocks.
  final String? plainText;

  /// Language id for code blocks (`c`, `cpp`, `x86asm`).
  final String? language;

  /// Table rows; the first row is the header.
  final List<List<String>> rows;

  static TheoryBlock? tryFromJson(Map<String, dynamic> json) {
    final typeName = JsonReader.readStringOrNull(json, 'type');
    if (typeName == null) return null;
    final type = TheoryBlockType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) return null;

    final rawRows = json['rows'];
    final rows = <List<String>>[];
    if (rawRows is List) {
      for (final row in rawRows) {
        if (row is List) rows.add(row.map((e) => e.toString()).toList());
      }
    }

    return TheoryBlock(
      type: type,
      text: JsonReader.readString(json, 'text'),
      items: JsonReader.readStringList(json, 'items'),
      latex: JsonReader.readStringOrNull(json, 'latex'),
      plainText: JsonReader.readStringOrNull(json, 'plainText'),
      language: JsonReader.readStringOrNull(json, 'language'),
      rows: rows,
    );
  }
}

/// The full study content of one topic: three tabs of blocks.
@immutable
class TheoryContent {
  const TheoryContent({
    required this.topicId,
    required this.concepts,
    required this.formulas,
    required this.notes,
  });

  final String topicId;
  final List<TheoryBlock> concepts;
  final List<TheoryBlock> formulas;
  final List<TheoryBlock> notes;

  static TheoryContent? tryFromJson(Map<String, dynamic> json) {
    final topicId = JsonReader.readStringOrNull(json, 'topicId');
    if (topicId == null) return null;

    List<TheoryBlock> parse(String key) => JsonReader.readMapList(json, key)
        .map(TheoryBlock.tryFromJson)
        .whereType<TheoryBlock>()
        .toList();

    return TheoryContent(
      topicId: topicId,
      concepts: parse('concepts'),
      formulas: parse('formulas'),
      notes: parse('notes'),
    );
  }

  bool get isEmpty => concepts.isEmpty && formulas.isEmpty && notes.isEmpty;
}
