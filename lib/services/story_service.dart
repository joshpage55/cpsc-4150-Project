import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:readright/models/story_model.dart';
import 'package:readright/services/story_repository.dart';

/// Result of a generateStory callable invocation.
class StoryGenerateResult {
  final StoryModel story;
  final int regenerationsRemainingToday;
  final bool softSpendAlert;
  final Map<String, dynamic>? usage;

  const StoryGenerateResult({
    required this.story,
    required this.regenerationsRemainingToday,
    this.softSpendAlert = false,
    this.usage,
  });
}

/// Teacher-facing Story Builder API.
///
/// All LLM calls go through the Firebase `generateStory` / `approveStory`
/// proxies — no OpenAI key in the Flutter client.
///
/// Person 2 owns UI screens; this service is the core logic they wire to.
class StoryService {
  StoryService({
    FirebaseFunctions? functions,
    StoryRepository? repository,
  })  : _functions = functions,
        _repository = repository ?? StoryRepository();

  Future<void> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // Ignore initialization failures here; the UI will still render and
      // the user can attempt generation once Firebase is configured.
    }
  }

  final FirebaseFunctions? _functions;
  final StoryRepository _repository;

  FirebaseFunctions get _functionsInstance {
    if (_functions != null) {
      return _functions!;
    }
    return FirebaseFunctions.instanceFor(region: 'us-central1');
  }

  StoryRepository get repository => _repository;

  /// Teacher selects student + reading level + interest + Dolch words → draft.
  Future<StoryGenerateResult> generateDraft({
    required String studentId,
    required String classId,
    required String readingLevel,
    required String interest,
    required List<String> dolchWords,
    int maxWords = 120,
  }) async {
    await _ensureFirebaseInitialized();
    final callable = _functionsInstance.httpsCallable('generateStory');
    final response = await callable.call(<String, dynamic>{
      'studentId': studentId,
      'classId': classId,
      'readingLevel': readingLevel,
      'interest': interest,
      'dolchWords': dolchWords,
      'maxWords': maxWords,
    });

    final data = Map<String, dynamic>.from(response.data as Map);
    final storyId = data['storyId'] as String? ?? '';
    final remaining = (data['regenerationsRemainingToday'] as num?)?.toInt() ?? 0;

    final story = StoryModel(
      id: storyId,
      status: StoryStatus.draft,
      text: data['story'] as String? ?? '',
      studentId: studentId,
      classId: classId,
      teacherId: _repository.currentUid ?? '',
      readingLevel: readingLevel,
      interest: interest,
      dolchWords: List<String>.from(dolchWords),
      model: data['model'] as String?,
      regenerationsRemainingToday: remaining,
    );

    return StoryGenerateResult(
      story: story,
      regenerationsRemainingToday: remaining,
      softSpendAlert: data['softSpendAlert'] == true,
      usage: data['usage'] is Map
          ? Map<String, dynamic>.from(data['usage'] as Map)
          : null,
    );
  }

  /// Teacher-in-the-loop: approve draft so student can read it.
  Future<StoryModel> approve(String storyId) async {
    await _ensureFirebaseInitialized();
    final callable = _functionsInstance.httpsCallable('approveStory');
    await callable.call(<String, dynamic>{'storyId': storyId});

    final updated = await _repository.fetchById(storyId);
    if (updated == null) {
      throw StateError('Approved story $storyId not found in Firestore');
    }
    return updated;
  }

  Future<int> remainingRegensToday(String teacherId) =>
      _repository.remainingRegensToday(teacherId);

  Future<List<StoryModel>> draftsForTeacher(String teacherId) =>
      _repository.fetchDraftsForTeacher(teacherId);

  Future<List<StoryModel>> approvedForStudent(String studentId) =>
      _repository.fetchApprovedForStudent(studentId);
}
