# Word Match engine (M3) — Person 1 core API

Person 2: build Start / Gameplay / Results screens on top.

```dart
final engine = WordMatchEngine();
final rounds = engine.buildSession(levelWords, questionCount: 10);

// Gameplay: play rounds[i].audioAssetPath, show rounds[i].choices (2×2)
// On tap: rounds[i].isCorrect(selected.id)

int correct = 0;
// … tally …
final result = engine.scoreSession(correct: correct, total: rounds.length);
// result.stars, result.encouragement → Results screen
```

Words must come from the same Dolch pool as practice (`WordRepository.fetchLevelWords`).
