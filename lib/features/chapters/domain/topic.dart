import 'package:flutter/foundation.dart';

import '../../../core/utils/validators.dart';

@immutable
class Topic {
  const Topic({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.subtitle,
    required this.order,
    required this.hasFormulas,
    required this.hasNotes,
    this.parentTopicId,
  });

  final String id;
  final String chapterId;
  final String title;
  final String subtitle;
  final int order;
  final bool hasFormulas;
  final bool hasNotes;

  /// Parent group topic; null for a top-level topic. A topic that other
  /// topics point to is a group, the ones pointing to it are its subtopics.
  final String? parentTopicId;

  static Topic? tryFromJson(Map<String, dynamic> json) {
    final id = JsonReader.readStringOrNull(json, 'id');
    final chapterId = JsonReader.readStringOrNull(json, 'chapterId');
    final title = JsonReader.readStringOrNull(json, 'title');
    if (id == null || chapterId == null || title == null) return null;
    return Topic(
      id: id,
      chapterId: chapterId,
      title: title,
      subtitle: JsonReader.readString(json, 'subtitle'),
      order: JsonReader.readInt(json, 'order'),
      hasFormulas: JsonReader.readBool(json, 'hasFormulas'),
      hasNotes: JsonReader.readBool(json, 'hasNotes', fallback: true),
      parentTopicId: JsonReader.readStringOrNull(json, 'parentTopicId'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterId': chapterId,
        'title': title,
        'subtitle': subtitle,
        'order': order,
        'hasFormulas': hasFormulas,
        'hasNotes': hasNotes,
        if (parentTopicId != null) 'parentTopicId': parentTopicId,
      };
}
