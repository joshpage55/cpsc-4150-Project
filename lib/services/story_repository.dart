import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:readright/models/story_model.dart';

/// Firestore access for AI Story Builder documents.
///
/// Collection: `stories`
class StoryRepository {
  StoryRepository._internal({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore,
        _auth = auth;

  factory StoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth}) =>
      StoryRepository._internal(firestore: firestore, auth: auth);

  StoryRepository.withFirestoreAndAuth(FirebaseFirestore firestore, FirebaseAuth auth)
      : _db = firestore,
        _auth = auth;

  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;

  FirebaseFirestore get _firestoreInstance => _db ?? FirebaseFirestore.instance;
  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestoreInstance.collection('stories');

  Future<StoryModel?> fetchById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return StoryModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (_) {
      return null;
    }
  }

  /// Drafts for the signed-in teacher (Person 2 preview queue).
  Future<List<StoryModel>> fetchDraftsForTeacher(String teacherId) async {
    try {
      final q = await _col
          .where('teacherId', isEqualTo: teacherId)
          .where('status', isEqualTo: StoryStatus.draft.wireName)
          .get();
      return q.docs
          .map((d) => StoryModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Approved stories visible to a student.
  Future<List<StoryModel>> fetchApprovedForStudent(String studentId) async {
    try {
      final q = await _col
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: StoryStatus.approved.wireName)
          .get();
      return q.docs
          .map((d) => StoryModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Remaining regenerations today for [teacherId] (PRD: 3/day).
  Future<int> remainingRegensToday(String teacherId, {int maxPerDay = 3}) async {
    try {
      final dayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      final doc =
          await _firestoreInstance.collection('story_regen_counters').doc('${teacherId}_$dayKey').get();
      final count = (doc.data()?['count'] as int?) ?? 0;
      final remaining = maxPerDay - count;
      return remaining < 0 ? 0 : remaining;
    } catch (_) {
      return 0;
    }
  }

  String? get currentUid {
    try {
      return _authInstance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
}
