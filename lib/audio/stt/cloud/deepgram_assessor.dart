import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:readright/audio/stt/pronunciation_assessor.dart';
import 'package:path/path.dart' as p;
import 'package:string_similarity/string_similarity.dart';

import '../on_device/cmu_map.dart';

/// Cloud STT via Firebase `transcribeAudio` proxy.
///
/// Deepgram API key lives only in the Cloud Function secret — never in this
/// Flutter binary / git history (stripped in M3).
class DeepgramAssessor implements PronunciationAssessor {
  final String audioPath;
  final String practiceWord;
  final FirebaseFunctions _functions;

  late String extension = '';

  DeepgramAssessor({
    required this.audioPath,
    required this.practiceWord,
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<AssessmentResult> assess({
    required String referenceText,
    required Uint8List audioBytes,
    required String locale,
  }) async {
    try {
      extension = p.extension(audioPath);
    } catch (e, st) {
      debugPrint('Audio path error: $e\n$st');
      return AssessmentResult(
        recognizedText: '',
        confidence: 0.0,
        score: 0.0,
        details: {'error': e.toString()},
      );
    }

    // Prefer encoded file on disk (WAV/AAC) over raw PCM buffer from caller.
    Uint8List payload = audioBytes;
    if (!kIsWeb && audioPath.isNotEmpty) {
      try {
        final file = File(audioPath);
        if (await file.exists()) {
          payload = await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('DeepgramAssessor: could not read $audioPath, using buffer: $e');
      }
    }

    final mimeType = _mimeForExtension(extension);
    try {
      final callable = _functions.httpsCallable('transcribeAudio');
      final response = await callable.call(<String, dynamic>{
        'audioBase64': base64Encode(payload),
        'mimeType': mimeType,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final transcript = (data['transcript'] as String?) ?? '';
      final modelConfidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

      debugPrint('transcript (via proxy): $transcript');
      return AssessmentResult(
        recognizedText: transcript,
        confidence: modelConfidence,
        score: setScore(transcript, practiceWord),
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'format': extension,
          'bytes': payload.length,
          'wordCount': transcript.trim().isEmpty
              ? 0
              : transcript.trim().split(RegExp(r'\s+')).length,
          'provider': data['provider'] ?? 'Deepgram Nova-3',
          'via': data['via'] ?? 'firebase-proxy',
          'finalized': true,
        },
      );
    } catch (e, st) {
      debugPrint('DeepgramAssessor proxy error: $e\n$st');
      return AssessmentResult(
        recognizedText: '',
        confidence: 0.0,
        score: 0.0,
        details: {'error': e.toString(), 'via': 'firebase-proxy'},
      );
    }
  }

  String _mimeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.wav':
        return 'audio/wav';
      case '.mp3':
        return 'audio/mpeg';
      case '.ogg':
        return 'audio/ogg';
      case '.webm':
        return 'audio/webm';
      case '.m4a':
      case '.aac':
        return 'audio/mp4';
      default:
        return 'audio/wav';
    }
  }

  double setScore(String transcript, String referenceWord) {
    double score = 0.0;
    double jaroScore = 0.0;
    double cmuScore = 0.0;

    final normReference = normalize(referenceWord);
    final normTranscript = normalize(transcript);

    final words = normTranscript.split(' ').where((w) => w.isNotEmpty).toList();
    double bestScore = 0.0;

    for (final word in words) {
      jaroScore = StringSimilarity.compareTwoStrings(normReference, word);
      if (jaroScore > bestScore) {
        bestScore = jaroScore;
      }
    }
    jaroScore = bestScore;

    if (jaroScore == 1.0) {
      cmuScore = 1.0;
    } else {
      final expectedPhonemes = cmuDict[normReference];
      if (expectedPhonemes != null) {
        bestScore = 0.0;
        for (final word in words) {
          final wordPhonemes = cmuDict[word];
          if (wordPhonemes == null) continue;
          cmuScore = comparePhonemes(expectedPhonemes, wordPhonemes);
          if (cmuScore > bestScore) {
            bestScore = cmuScore;
          }
        }
        cmuScore = bestScore;
      }
    }

    const cmuWeight = 0.7;
    const jaroWeight = 0.3;
    score = (cmuScore * cmuWeight) + (jaroScore * jaroWeight);
    return score;
  }

  String normalize(String subject) {
    var normalized = subject.toLowerCase();
    normalized =
        normalized.replaceAll(RegExp(r'[0-9\p{P}]', unicode: true), '');
    return normalized.trim();
  }

  double comparePhonemes(List<String> refPhonemes, List<String> actualPhonemes) {
    final distance = levenshteinList(refPhonemes, actualPhonemes);
    final maxLen = refPhonemes.length > actualPhonemes.length
        ? refPhonemes.length
        : actualPhonemes.length;
    if (maxLen == 0) return 0.0;
    return 1.0 - (distance / maxLen);
  }

  int levenshteinList(List<String> expectedPhonemes, List<String> actualPhonemes) {
    final expectedLength = expectedPhonemes.length;
    final actualLength = actualPhonemes.length;

    final matrix = List.generate(
      expectedLength + 1,
      (_) => List<int>.filled(actualLength + 1, 0),
    );

    for (var i = 0; i <= expectedLength; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= actualLength; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= expectedLength; i++) {
      for (var j = 1; j <= actualLength; j++) {
        final substitutionCost =
            expectedPhonemes[i - 1] == actualPhonemes[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + substitutionCost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[expectedLength][actualLength];
  }
}
