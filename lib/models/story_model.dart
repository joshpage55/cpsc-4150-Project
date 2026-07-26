import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a teacher-generated AI story.
enum StoryStatus {
  draft,
  approved,
}

extension StoryStatusX on StoryStatus {
  String get wireName => name;

  static StoryStatus fromString(String? value) {
    final v = (value ?? '').toLowerCase();
    if (v == 'approved') return StoryStatus.approved;
    return StoryStatus.draft;
  }
}

/// Firestore document for AI Story Builder drafts / approved stories.
///
/// Collection: `stories`
class StoryModel {
  final String id;
  final StoryStatus status;
  final String text;
  final String studentId;
  final String classId;
  final String teacherId;
  final String readingLevel;
  final String interest;
  final List<String> dolchWords;
  final String? model;
  final int? regenerationsRemainingToday;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  const StoryModel({
    required this.id,
    required this.status,
    required this.text,
    required this.studentId,
    required this.classId,
    required this.teacherId,
    required this.readingLevel,
    required this.interest,
    required this.dolchWords,
    this.model,
    this.regenerationsRemainingToday,
    this.createdAt,
    this.approvedAt,
  });

  StoryModel copyWith({
    String? id,
    StoryStatus? status,
    String? text,
    String? studentId,
    String? classId,
    String? teacherId,
    String? readingLevel,
    String? interest,
    List<String>? dolchWords,
    String? model,
    int? regenerationsRemainingToday,
    DateTime? createdAt,
    DateTime? approvedAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      status: status ?? this.status,
      text: text ?? this.text,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      readingLevel: readingLevel ?? this.readingLevel,
      interest: interest ?? this.interest,
      dolchWords: dolchWords ?? this.dolchWords,
      model: model ?? this.model,
      regenerationsRemainingToday:
          regenerationsRemainingToday ?? this.regenerationsRemainingToday,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.wireName,
      'text': text,
      'studentId': studentId,
      'classId': classId,
      'teacherId': teacherId,
      'readingLevel': readingLevel,
      'interest': interest,
      'dolchWords': dolchWords,
      'model': model,
      'regenerationsRemainingToday': regenerationsRemainingToday,
    };
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    DateTime? asDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return StoryModel(
      id: (json['id'] as String?) ?? '',
      status: StoryStatusX.fromString(json['status'] as String?),
      text: (json['text'] as String?) ?? '',
      studentId: (json['studentId'] as String?) ?? '',
      classId: (json['classId'] as String?) ?? '',
      teacherId: (json['teacherId'] as String?) ?? '',
      readingLevel: (json['readingLevel'] as String?) ?? 'first grade',
      interest: (json['interest'] as String?) ?? '',
      dolchWords: List<String>.from(json['dolchWords'] as List? ?? const []),
      model: json['model'] as String?,
      regenerationsRemainingToday: json['regenerationsRemainingToday'] as int?,
      createdAt: asDate(json['createdAt']),
      approvedAt: asDate(json['approvedAt']),
    );
  }
}
