import 'package:flutter/foundation.dart';

import '../../../core/utils/validators.dart';

@immutable
class Formula {
  const Formula({
    required this.id,
    required this.chapterId,
    required this.topicId,
    required this.title,
    required this.plainText,
    this.latex,
    this.isCode = false,
    this.description = '',
  });

  final String id;
  final String chapterId;
  final String topicId;
  final String title;

  /// Always present — the fallback rendering and search text.
  final String plainText;

  /// LaTeX source; null for code-style entries.
  final String? latex;

  /// True for programming syntax references rendered as code.
  final bool isCode;
  final String description;

  static Formula? tryFromJson(Map<String, dynamic> json) {
    final id = JsonReader.readStringOrNull(json, 'id');
    final chapterId = JsonReader.readStringOrNull(json, 'chapterId');
    final title = JsonReader.readStringOrNull(json, 'title');
    final plainText = JsonReader.readStringOrNull(json, 'plainText');
    if (id == null || chapterId == null || title == null || plainText == null) {
      return null;
    }
    return Formula(
      id: id,
      chapterId: chapterId,
      topicId: JsonReader.readString(json, 'topicId'),
      title: title,
      plainText: plainText,
      latex: JsonReader.readStringOrNull(json, 'latex'),
      isCode: JsonReader.readBool(json, 'isCode'),
      description: JsonReader.readString(json, 'description'),
    );
  }
}
