import 'package:readright/utils/enums.dart';

/// Pronunciation scoring thresholds and kid-facing feedback hints.
class AppScoring {
  /// Default pass bar (~3.5 / 5 stars). Prefer [passingThresholdForLevel].
  static const double passingThreshold = 0.70;

  /// Slightly easier early Dolch levels; tighter for later grades.
  static double passingThresholdForLevel(WordLevel? level) {
    switch (level) {
      case WordLevel.prePrimer:
      case WordLevel.primer:
        return 0.62;
      case WordLevel.firstGrade:
      case WordLevel.secondGrade:
        return 0.68;
      case WordLevel.thirdGrade:
      case WordLevel.fourthGrade:
      case WordLevel.fifthGrade:
        return 0.74;
      case WordLevel.custom:
      case null:
        return passingThreshold;
    }
  }

  /// One actionable tip when the attempt is below the pass bar (DMMT / PRD).
  static String kidHintForAttempt({
    required String word,
    required double rawScore,
    WordLevel? level,
    String? transcript,
  }) {
    final threshold = passingThresholdForLevel(level);
    final target = word.trim().isEmpty ? 'the word' : word.trim().toLowerCase();

    if (rawScore >= threshold) {
      return 'Nice work saying "$target"! Try the next word.';
    }

    final heard = (transcript ?? '').trim().toLowerCase();
    if (heard.isEmpty) {
      return 'I did not hear "$target". Hold the mic close and say it slowly.';
    }
    if (rawScore < 0.35) {
      return 'Say only "$target" — nice and slow. Then tap Retry.';
    }
    if (rawScore < 0.55) {
      return 'Almost! Stretch the sounds in "$target" and try once more.';
    }
    return 'So close on "$target"! One more clear try.';
  }

  /// Star-oriented encouragement copy (0–5 stars).
  static String starMessage(double stars) {
    if (stars >= 5.0) return 'Excellent! Perfect pronunciation!';
    if (stars >= 4.0) return 'Great job!';
    if (stars >= 3.5) return 'Good work — you passed!';
    if (stars >= 2.0) return 'Not bad, keep practicing!';
    if (stars >= 0.0) return 'Oh no — let\'s try again!';
    return 'Let us try again!';
  }
}
