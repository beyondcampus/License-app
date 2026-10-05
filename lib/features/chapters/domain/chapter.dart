import 'package:flutter/foundation.dart';

import '../../../core/utils/validators.dart';

@immutable
class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.order,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final int order;

  /// Returns null when required fields are missing (entry is skipped).
  static Chapter? tryFromJson(Map<String, dynamic> json) {
    final id = JsonReader.readStringOrNull(json, 'id');
    final title = JsonReader.readStringOrNull(json, 'title');
    if (id == null || title == null) return null;
    return Chapter(
      id: id,
      title: title,
      description: JsonReader.readString(json, 'description'),
      emoji: JsonReader.readString(json, 'emoji', fallback: '📘'),
      order: JsonReader.readInt(json, 'order'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'order': order,
      };
}
