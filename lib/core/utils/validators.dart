import 'dart:convert';

/// Defensive JSON reading helpers. Content rows come from Supabase, and the
/// app must never crash on a malformed entry (Stage 11 requirement) — bad
/// values fall back to safe defaults and bad entries are skipped upstream.
abstract final class JsonReader {
  static String readString(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final v = json[key];
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return fallback;
  }

  static String? readStringOrNull(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
    if (v is num || v is bool) return v.toString();
    return null;
  }

  static int readInt(
    Map<String, dynamic> json,
    String key, {
    int fallback = 0,
  }) {
    final v = json[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double readDouble(
    Map<String, dynamic> json,
    String key, {
    double fallback = 0,
  }) {
    final v = json[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool readBool(
    Map<String, dynamic> json,
    String key, {
    bool fallback = false,
  }) {
    final v = json[key];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static List<String> readStringList(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is List) return v.whereType<String>().toList();
    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } on FormatException {
        // Invalid JSON is treated as an empty list by design.
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> readMapList(
    Map<String, dynamic> json,
    String key,
  ) {
    final v = json[key];
    if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    return const [];
  }
}
