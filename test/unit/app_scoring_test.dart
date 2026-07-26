import 'package:flutter_test/flutter_test.dart';
import 'package:readright/utils/app_scoring.dart';
import 'package:readright/utils/enums.dart';

void main() {
  group('AppScoring.passingThreshold', () {
    test('default threshold is 0.70', () {
      expect(AppScoring.passingThreshold, 0.70);
    });
  });

  group('AppScoring.passingThresholdForLevel', () {
    test('early levels (pre-primer, primer) use the easier 0.62 bar', () {
      expect(AppScoring.passingThresholdForLevel(WordLevel.prePrimer), 0.62);
      expect(AppScoring.passingThresholdForLevel(WordLevel.primer), 0.62);
    });

    test('first/second grade use the 0.68 bar', () {
      expect(AppScoring.passingThresholdForLevel(WordLevel.firstGrade), 0.68);
      expect(AppScoring.passingThresholdForLevel(WordLevel.secondGrade), 0.68);
    });

    test('third/fourth/fifth grade use the stricter 0.74 bar', () {
      expect(AppScoring.passingThresholdForLevel(WordLevel.thirdGrade), 0.74);
      expect(AppScoring.passingThresholdForLevel(WordLevel.fourthGrade), 0.74);
      expect(AppScoring.passingThresholdForLevel(WordLevel.fifthGrade), 0.74);
    });

    test('custom level falls back to the default passing threshold', () {
      expect(
        AppScoring.passingThresholdForLevel(WordLevel.custom),
        AppScoring.passingThreshold,
      );
    });

    test('null level falls back to the default passing threshold', () {
      expect(
        AppScoring.passingThresholdForLevel(null),
        AppScoring.passingThreshold,
      );
    });
  });

  group('AppScoring.kidHintForAttempt', () {
    test('praises the attempt when the score meets the level threshold', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'cat',
        rawScore: 0.70,
        level: WordLevel.firstGrade, // threshold 0.68
        transcript: 'cat',
      );
      expect(hint, 'Nice work saying "cat"! Try the next word.');
    });

    test('praises using default threshold when no level is given', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'dog',
        rawScore: 0.90,
        transcript: 'dog',
      );
      expect(hint, contains('Nice work saying "dog"'));
    });

    test('prompts to speak up when transcript is empty', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'sun',
        rawScore: 0.10,
        transcript: '',
      );
      expect(hint, 'I did not hear "sun". Hold the mic close and say it slowly.');
    });

    test('prompts to speak up when transcript is null', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'sun',
        rawScore: 0.10,
      );
      expect(hint, contains('I did not hear "sun"'));
    });

    test('prompts to speak up when transcript is only whitespace', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'sun',
        rawScore: 0.10,
        transcript: '   ',
      );
      expect(hint, contains('I did not hear "sun"'));
    });

    test('gives the "say it slowly" tip for very low scores below 0.35', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'red',
        rawScore: 0.20,
        transcript: 'wed',
      );
      expect(hint, 'Say only "red" — nice and slow. Then tap Retry.');
    });

    test('gives the "almost" tip for scores between 0.35 and 0.55', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'red',
        rawScore: 0.40,
        transcript: 'wed',
      );
      expect(hint, 'Almost! Stretch the sounds in "red" and try once more.');
    });

    test('gives the "so close" tip for scores between 0.55 and threshold', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'red',
        rawScore: 0.60,
        level: WordLevel.firstGrade, // threshold 0.68
        transcript: 'wed',
      );
      expect(hint, 'So close on "red"! One more clear try.');
    });

    test('boundary score exactly at 0.35 is not treated as "very low"', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'red',
        rawScore: 0.35,
        transcript: 'wed',
      );
      expect(hint, contains('Almost! Stretch the sounds'));
    });

    test('boundary score exactly at 0.55 is not treated as "almost"', () {
      final hint = AppScoring.kidHintForAttempt(
        word: 'red',
        rawScore: 0.55,
        transcript: 'wed',
      );
      expect(hint, contains('So close on "red"'));
    });

    test('falls back to "the word" when word is blank', () {
      final hint = AppScoring.kidHintForAttempt(
        word: '   ',
        rawScore: 0.10,
        transcript: '',
      );
      expect(hint, contains('the word'));
    });

    test('lowercases and trims the target word in feedback', () {
      final hint = AppScoring.kidHintForAttempt(
        word: '  CAT  ',
        rawScore: 0.95,
        transcript: 'cat',
      );
      expect(hint, 'Nice work saying "cat"! Try the next word.');
    });
  });

  group('AppScoring.starMessage', () {
    test('5 stars or more is "Excellent"', () {
      expect(AppScoring.starMessage(5.0), 'Excellent! Perfect pronunciation!');
      expect(AppScoring.starMessage(5.5), 'Excellent! Perfect pronunciation!');
    });

    test('4 up to just under 5 stars is "Great job"', () {
      expect(AppScoring.starMessage(4.0), 'Great job!');
      expect(AppScoring.starMessage(4.9), 'Great job!');
    });

    test('3.5 up to just under 4 stars is the passing message', () {
      expect(AppScoring.starMessage(3.5), 'Good work — you passed!');
      expect(AppScoring.starMessage(3.9), 'Good work — you passed!');
    });

    test('2 up to just under 3.5 stars is "keep practicing"', () {
      expect(AppScoring.starMessage(2.0), 'Not bad, keep practicing!');
      expect(AppScoring.starMessage(3.4), 'Not bad, keep practicing!');
    });

    test('0 up to just under 2 stars is the "try again" message', () {
      expect(AppScoring.starMessage(0.0), 'Oh no — let\'s try again!');
      expect(AppScoring.starMessage(1.9), 'Oh no — let\'s try again!');
    });

    test('negative stars fall through to the final fallback message', () {
      expect(AppScoring.starMessage(-1.0), 'Let us try again!');
    });
  });

  // ---------------------------------------------------------------------
  // Fixtures from data/seed_words.csv: the CSV ships categories like
  // "Dolch Pre-Primer", "Dolch First Grade", etc. These tests confirm how
  // that real category text resolves through wordLevelFromString and,
  // ultimately, into the passing threshold used by the scoring helpers.
  // ---------------------------------------------------------------------
  group('AppScoring with real seed_words.csv categories', () {
    test(
      'raw CSV category text ("Dolch Pre-Primer") does not match the '
      'Pre-Primer enum label, so it resolves to WordLevel.custom',
      () {
        // wordLevelFromString compares against the enum identifier and the
        // display name ("Pre-Primer"), neither of which includes the
        // "Dolch " prefix used in seed_words.csv's Category column.
        final level = wordLevelFromString('Dolch Pre-Primer');
        expect(level, WordLevel.custom);
        expect(
          AppScoring.passingThresholdForLevel(level),
          AppScoring.passingThreshold,
        );
      },
    );

    test(
      'stripping the "Dolch " prefix resolves the CSV category to the '
      'correct WordLevel and threshold',
      () {
        const csvCategories = <String, WordLevel>{
          'Dolch Pre-Primer': WordLevel.prePrimer,
          'Dolch Primer': WordLevel.primer,
          'Dolch First Grade': WordLevel.firstGrade,
          'Dolch Second Grade': WordLevel.secondGrade,
          'Dolch Third Grade': WordLevel.thirdGrade,
          'Dolch Fourth Grade': WordLevel.fourthGrade,
          'Dolch Fifth Grade': WordLevel.fifthGrade,
        };

        csvCategories.forEach((category, expectedLevel) {
          final stripped = category.replaceFirst('Dolch ', '');
          final level = wordLevelFromString(stripped);
          expect(level, expectedLevel, reason: 'category: $category');
        });

        // Spot-check the resulting thresholds match the tiering described
        // in AppScoring's own doc comments.
        expect(
          AppScoring.passingThresholdForLevel(WordLevel.prePrimer),
          0.62,
        );
        expect(
          AppScoring.passingThresholdForLevel(WordLevel.firstGrade),
          0.68,
        );
        expect(
          AppScoring.passingThresholdForLevel(WordLevel.fifthGrade),
          0.74,
        );
      },
    );

    test('kidHintForAttempt works end-to-end with a real Dolch word and level', () {
      // "big" is Dolch Pre-Primer word #4 in seed_words.csv.
      final level = wordLevelFromString(
        'Dolch Pre-Primer'.replaceFirst('Dolch ', ''),
      );
      final hint = AppScoring.kidHintForAttempt(
        word: 'big',
        rawScore: 0.65, // above the 0.62 Pre-Primer bar
        level: level,
        transcript: 'big',
      );
      expect(hint, 'Nice work saying "big"! Try the next word.');
    });
  });
}
