import 'package:flutter/foundation.dart';

import '../../../core/utils/validators.dart';

enum Difficulty { easy, medium, hard }

@immutable
class Question {
  const Question({
    required this.id,
    required this.chapterId,
    required this.topicId,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    this.codeSnippet,
    this.codeLanguage,
    this.formula,
  });

  final String id;
  final String chapterId;
  final String topicId;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final Difficulty difficulty;

  /// Optional code shown between the question and the options.
  final String? codeSnippet;
  final String? codeLanguage;

  /// Optional LaTeX formula shown with the question.
  final String? formula;

  /// Returns null for structurally invalid questions (skipped, never crash).
  static Question? tryFromJson(Map<String, dynamic> json) {
    final id = JsonReader.readStringOrNull(json, 'id');
    final chapterId = JsonReader.readStringOrNull(json, 'chapterId');
    final topicId = JsonReader.readStringOrNull(json, 'topicId');
    final text = JsonReader.readStringOrNull(json, 'questionText');
    final options = JsonReader.readStringList(json, 'options');
    var correctIndex = JsonReader.readInt(json, 'correctIndex', fallback: -1);
    if (correctIndex < 0) {
      final correctAnswer = JsonReader.readStringOrNull(json, 'correctAnswer');
      if (correctAnswer != null) {
        correctIndex = options.indexOf(correctAnswer);
        if (correctIndex < 0 && correctAnswer.length == 1) {
          final letter = correctAnswer.toUpperCase().codeUnitAt(0) - 65;
          if (letter >= 0 && letter < options.length) {
            correctIndex = letter;
          }
        }
      }
    }
    if (id == null || chapterId == null || topicId == null || text == null) {
      return null;
    }
    if (options.length < 2 ||
        correctIndex < 0 ||
        correctIndex >= options.length) {
      return null;
    }
    final difficultyName = JsonReader.readString(
      json,
      'difficulty',
      fallback: 'medium',
    ).toLowerCase();
    return Question(
      id: id,
      chapterId: chapterId,
      topicId: topicId,
      questionText: text,
      options: options,
      correctIndex: correctIndex,
      explanation: JsonReader.readString(json, 'explanation'),
      difficulty:
          Difficulty.values
              .where((d) => d.name == difficultyName)
              .firstOrNull ??
          Difficulty.medium,
      codeSnippet: JsonReader.readStringOrNull(json, 'codeSnippet'),
      codeLanguage: JsonReader.readStringOrNull(json, 'codeLanguage'),
      formula: JsonReader.readStringOrNull(json, 'formula'),
    );
  }
}
