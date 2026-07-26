import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readright/games/word_match_engine.dart';
import 'package:readright/models/story_model.dart';
import 'package:readright/models/word_model.dart';
import 'package:readright/utils/app_scoring.dart';
import 'package:readright/utils/enums.dart';

void main() {
  group('AppScoring', () {
    test('early levels use a lower pass bar than later grades', () {
      expect(
        AppScoring.passingThresholdForLevel(WordLevel.prePrimer),
        lessThan(AppScoring.passingThresholdForLevel(WordLevel.fifthGrade)),
      );
    });

    test('kid hint is actionable when score is low', () {
      final tip = AppScoring.kidHintForAttempt(
        word: 'away',
        rawScore: 0.2,
        level: WordLevel.prePrimer,
        transcript: '',
      );
      expect(tip.toLowerCase(), contains('away'));
      expect(tip.toLowerCase(), anyOf(contains('mic'), contains('slowly'), contains('hear')));
    });

    test('kid hint celebrates a pass', () {
      final tip = AppScoring.kidHintForAttempt(
        word: 'blue',
        rawScore: 0.9,
        level: WordLevel.prePrimer,
      );
      expect(tip.toLowerCase(), contains('nice'));
    });
  });

  group('WordMatchEngine', () {
    test('builds rounds with four choices including the target', () {
      final words = List.generate(
        8,
        (i) => WordModel(
          text: 'word$i',
          level: WordLevel.prePrimer,
          levelOrder: i + 1,
          sentences: const ['Example.'],
        ),
      );
      final engine = WordMatchEngine(random: Random(42));
      final rounds = engine.buildSession(words, questionCount: 5);

      expect(rounds.length, 5);
      for (final round in rounds) {
        expect(round.choices.length, WordMatchEngine.choicesPerRound);
        expect(round.choices.any((c) => c.id == round.target.id), isTrue);
        expect(round.isCorrect(round.target.id), isTrue);
        expect(round.audioAssetPath, contains(round.target.text.toLowerCase()));
      }
    });

    test('scores a session into stars and encouragement', () {
      final result = WordMatchEngine().scoreSession(correct: 8, total: 10);
      expect(result.stars, inInclusiveRange(0, 5));
      expect(result.encouragement, isNotEmpty);
      expect(result.accuracy, closeTo(0.8, 0.001));
    });

    test('throws when pool is too small for four tiles', () {
      final tiny = [
        WordModel(
          text: 'a',
          level: WordLevel.prePrimer,
          levelOrder: 1,
          sentences: const [],
        ),
      ];
      expect(
        () => WordMatchEngine().buildSession(tiny),
        throwsArgumentError,
      );
    });
  });

  group('StoryModel', () {
    test('round-trips draft JSON', () {
      final story = StoryModel(
        id: 'abc',
        status: StoryStatus.draft,
        text: 'Sam can find a big blue ball.',
        studentId: 's1',
        classId: 'c1',
        teacherId: 't1',
        readingLevel: 'Pre-Primer',
        interest: 'dogs',
        dolchWords: const ['a', 'big', 'blue', 'can', 'find'],
        model: 'gpt-4o-mini',
        regenerationsRemainingToday: 2,
      );
      final again = StoryModel.fromJson(story.toJson());
      expect(again.id, story.id);
      expect(again.status, StoryStatus.draft);
      expect(again.dolchWords.length, 5);
      expect(again.interest, 'dogs');
    });

    test('parses approved status', () {
      final story = StoryModel.fromJson({
        'id': 'x',
        'status': 'approved',
        'text': 'hi',
        'studentId': 's',
        'classId': 'c',
        'teacherId': 't',
        'readingLevel': 'first grade',
        'interest': 'cats',
        'dolchWords': <String>['a'],
      });
      expect(story.status, StoryStatus.approved);
    });
  });
}
