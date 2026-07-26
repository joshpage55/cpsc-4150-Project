import 'dart:math';

import 'package:readright/models/word_model.dart';
import 'package:readright/utils/app_constants.dart';
import 'package:readright/utils/enums.dart';

/// One Word Match question: hear/see target → pick among 4 Dolch tiles.
class WordMatchRound {
  final WordModel target;
  final List<WordModel> choices;
  final int index;
  final int total;

  const WordMatchRound({
    required this.target,
    required this.choices,
    required this.index,
    required this.total,
  });

  /// Asset path convention used elsewhere for pre-generated word MP3s.
  String get audioAssetPath =>
      '${AppConstants.assetPathWords}${target.text.trim().toLowerCase()}.mp3';

  bool isCorrect(String wordId) => wordId == target.id;

  bool isCorrectText(String text) =>
      text.trim().toLowerCase() == target.text.trim().toLowerCase();
}

/// End-of-session summary for Person 2 results screen.
class WordMatchResult {
  final int correct;
  final int total;
  final int stars;
  final String encouragement;

  const WordMatchResult({
    required this.correct,
    required this.total,
    required this.stars,
    required this.encouragement,
  });

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// Pure game engine for Word Match (PRD Game 1).
///
/// Person 2 builds Start / Gameplay / Results screens on top of this.
class WordMatchEngine {
  WordMatchEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const int defaultQuestionCount = 10;
  static const int choicesPerRound = 4;

  /// Build a full session from same-level Dolch words (seed / Firestore).
  List<WordMatchRound> buildSession(
    List<WordModel> levelWords, {
    int questionCount = defaultQuestionCount,
    WordLevel? requireLevel,
  }) {
    final pool = levelWords
        .where((w) => requireLevel == null || w.level == requireLevel)
        .where((w) => w.text.trim().isNotEmpty)
        .toList();

    if (pool.length < choicesPerRound) {
      throw ArgumentError(
        'Need at least $choicesPerRound Dolch words in the level pool '
        '(got ${pool.length}).',
      );
    }

    final count = questionCount.clamp(1, pool.length);
    final targets = List<WordModel>.from(pool)..shuffle(_random);
    final selected = targets.take(count).toList();

    final rounds = <WordMatchRound>[];
    for (var i = 0; i < selected.length; i++) {
      rounds.add(_buildRound(
        target: selected[i],
        pool: pool,
        index: i + 1,
        total: selected.length,
      ));
    }
    return rounds;
  }

  WordMatchRound _buildRound({
    required WordModel target,
    required List<WordModel> pool,
    required int index,
    required int total,
  }) {
    final distractors = pool.where((w) => w.id != target.id).toList()
      ..shuffle(_random);
    final picks = distractors.take(choicesPerRound - 1).toList();
    final choices = <WordModel>[target, ...picks]..shuffle(_random);

    return WordMatchRound(
      target: target,
      choices: choices,
      index: index,
      total: total,
    );
  }

  /// Score a completed session (stars map 0–5 for UI parity with practice).
  WordMatchResult scoreSession({
    required int correct,
    required int total,
  }) {
    final safeTotal = total <= 0 ? 1 : total;
    final ratio = correct / safeTotal;
    final stars = (ratio * 5).round().clamp(0, 5);
    final encouragement = switch (stars) {
      5 => 'Perfect match! You know these words!',
      4 => 'Great job! Keep practicing!',
      3 => 'Nice work — play again to earn more stars!',
      2 => 'Keep practicing — you are learning!',
      _ => 'Try again — listen carefully, then tap the word!',
    };
    return WordMatchResult(
      correct: correct,
      total: total,
      stars: stars,
      encouragement: encouragement,
    );
  }
}
