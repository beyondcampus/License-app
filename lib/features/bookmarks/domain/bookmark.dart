import 'package:flutter/foundation.dart';

/// What kind of item a bookmark points at.
enum BookmarkType { question, formula, topic }

@immutable
class Bookmark {
  const Bookmark({
    required this.type,
    required this.itemId,
    required this.createdAt,
  });

  final BookmarkType type;
  final String itemId;
  final DateTime createdAt;

  Map<String, dynamic> toDbMap() => {
        'item_type': type.name,
        'item_id': itemId,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  static Bookmark? fromDbMap(Map<String, dynamic> map) {
    final type = BookmarkType.values
        .where((t) => t.name == map['item_type'])
        .firstOrNull;
    final itemId = map['item_id'] as String?;
    if (type == null || itemId == null) return null;
    return Bookmark(
      type: type,
      itemId: itemId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as num?)?.toInt() ?? 0),
    );
  }
}
