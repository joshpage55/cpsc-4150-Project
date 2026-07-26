# Story Builder (M3) — Person 1 core API

Person 2: wire UI to these entry points.

## Teacher generate → approve

```dart
final stories = StoryService();

final draft = await stories.generateDraft(
  studentId: student.id!,
  classId: classSection.id,
  readingLevel: 'Pre-Primer',
  interest: 'dogs',
  dolchWords: levelWords.map((w) => w.text).toList(),
);

// Show draft.story.text for preview…
await stories.approve(draft.story.id);
```

## Student read approved stories

```dart
final list = await stories.approvedForStudent(studentId);
```

## Remaining regenerations (3/day)

```dart
final left = await stories.remainingRegensToday(teacherId);
```

All LLM traffic goes through Cloud Functions — no OpenAI key in Flutter.
