import 'dart:convert';
import 'dart:math' show log, ln2;

class SolfegeExercise {
  final String id;
  final String title;
  final String difficultyLevel;
  final int difficultyValue;
  final String keySignature;
  final String timeSignature;
  final int tempo;
  final List<NoteInfo> noteSequence;
  final DateTime createdAt;
  final String clef;
  final bool isOctaveDown;

  SolfegeExercise({
    required this.id,
    required this.title,
    required this.difficultyLevel,
    required this.difficultyValue,
    required this.keySignature,
    required this.timeSignature,
    required this.tempo,
    required this.noteSequence,
    required this.createdAt,
    this.clef = 'treble',
    this.isOctaveDown = false,
  });

  factory SolfegeExercise.fromJson(Map<String, dynamic> json) {
    List<NoteInfo> notes = [];
    if (json['note_sequence'] != null) {
      final sequence = json['note_sequence'] is String
          ? jsonDecode(json['note_sequence'])
          : json['note_sequence'];
      if (sequence is List) {
        notes = sequence.map((e) => NoteInfo.fromJson(e)).toList();
      }
    }
    return SolfegeExercise(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      difficultyLevel: json['difficulty_level']?.toString() ?? 'basico',
      difficultyValue:
          int.tryParse(json['difficulty_value']?.toString() ?? '1') ?? 1,
      keySignature: json['key_signature']?.toString() ?? 'C',
      timeSignature: json['time_signature']?.toString() ?? '4/4',
      tempo: int.tryParse(json['tempo']?.toString() ?? '100') ?? 100,
      noteSequence: notes,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      clef: json['clef']?.toString() ?? 'treble',
      isOctaveDown: json['is_octave_down']?.toString() == 'true' || json['is_octave_down'] == true,
    );
  }

  factory SolfegeExercise.fromMap(Map<String, dynamic> map) {
    return SolfegeExercise.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty_level': difficultyLevel,
      'difficulty_value': difficultyValue,
      'key_signature': keySignature,
      'time_signature': timeSignature,
      'tempo': tempo,
      'note_sequence': jsonEncode(noteSequence.map((note) => note.toJson()).toList()),
      'created_at': createdAt.toIso8601String(),
      'clef': clef,
      'is_octave_down': isOctaveDown,
    };
  }
}

class NoteInfo {
  final String note;
  final String lyric;
  final String duration;

  NoteInfo({
    required this.note,
    required this.lyric,
    required this.duration,
  });

  factory NoteInfo.fromJson(Map<String, dynamic> json) {
    return NoteInfo(
      note: json['note']?.toString() ?? '',
      lyric: json['lyric']?.toString() ?? '',
      duration: json['duration']?.toString() ?? 'quarter',
    );
  }

  // Correção: Adicionado o método toJson que estava faltando.
  Map<String, dynamic> toJson() => {
        'note': note,
        'lyric': lyric,
        'duration': duration,
      };

  double get frequency {
    const frequencies = {
      'C4': 261.63,
      'C#4': 277.18,
      'D4': 293.66,
      'D#4': 311.13,
      'E4': 329.63,
      'F4': 349.23,
      'F#4': 369.99,
      'G4': 392.00,
      'G#4': 415.30,
      'A4': 440.00,
      'A#4': 466.16,
      'B4': 493.88,
      'C5': 523.25,
    };
    return frequencies[note] ?? 440.0;
  }

  // Método para obter frequência transposta uma oitava abaixo
  double getFrequencyOctaveDown() {
    return frequency / 2.0;
  }

  double getDurationInSeconds(int tempo) {
    final beatDuration = 60.0 / tempo;
    const durations = {
      'whole': 4.0,
      'half': 2.0,
      'quarter': 1.0,
      'eighth': 0.5,
      '16th': 0.25,
      '32nd': 0.125,
      '64th': 0.0625
    };
    return beatDuration * (durations[duration] ?? 1.0);
  }
}

// Enums para análise detalhada de erros
enum PitchErrorDirection { tooHigh, tooLow, correct, notSung }
enum ErrorSeverity { slight, moderate, severe }

// Definição ÚNICA e CORRETA da classe de resultados.
class NoteResult {
  final NoteInfo expectedNote;
  final String detectedName;
  final double detectedFrequency;
  final double detectedDuration;
  final bool pitchCorrect;
  final bool durationCorrect;
  final bool nameCorrect;
  // Análise detalhada de erros
  final PitchErrorDirection pitchErrorDirection;
  final ErrorSeverity pitchErrorSeverity;
  final double centsDifference; // Diferença em cents
  final double durationDifference; // Diferença em segundos

  NoteResult({
    required this.expectedNote,
    required this.detectedName,
    required this.detectedFrequency,
    required this.detectedDuration,
    required this.pitchCorrect,
    required this.durationCorrect,
    required this.nameCorrect,
    this.pitchErrorDirection = PitchErrorDirection.correct,
    this.pitchErrorSeverity = ErrorSeverity.slight,
    this.centsDifference = 0.0,
    this.durationDifference = 0.0,
  });

  // Calcular diferença em cents entre duas frequências
  static double calculateCentsDifference(double expectedFreq, double detectedFreq) {
    if (expectedFreq <= 0 || detectedFreq <= 0) return 0.0;
    return 1200 * log(detectedFreq / expectedFreq) / ln2;
  }

  // Determinar direção e severidade do erro de pitch
  static PitchErrorDirection determinePitchDirection(double expectedFreq, double detectedFreq) {
    if (detectedFreq <= 0) return PitchErrorDirection.notSung;
    if (detectedFreq > expectedFreq) return PitchErrorDirection.tooHigh;
    if (detectedFreq < expectedFreq) return PitchErrorDirection.tooLow;
    return PitchErrorDirection.correct;
  }

  static ErrorSeverity determinePitchSeverity(double centsDiff) {
    final absCents = centsDiff.abs();
    if (absCents < 30) return ErrorSeverity.slight;    // < 30 cents
    if (absCents < 100) return ErrorSeverity.moderate; // 30-100 cents
    return ErrorSeverity.severe;                       // > 100 cents
  }

  // Método factory para criar resultado com análise detalhada
  factory NoteResult.withDetailedAnalysis({
    required NoteInfo expectedNote,
    required String detectedName,
    required double detectedFrequency,
    required double detectedDuration,
    required bool pitchCorrect,
    required bool durationCorrect,
    required bool nameCorrect,
    required double expectedFrequency,
    required double expectedDuration,
  }) {
    final centsDiff = calculateCentsDifference(expectedFrequency, detectedFrequency);
    final pitchDirection = determinePitchDirection(expectedFrequency, detectedFrequency);
    final pitchSeverity = determinePitchSeverity(centsDiff);
    final durationDiff = detectedDuration - expectedDuration;

    return NoteResult(
      expectedNote: expectedNote,
      detectedName: detectedName,
      detectedFrequency: detectedFrequency,
      detectedDuration: detectedDuration,
      pitchCorrect: pitchCorrect,
      durationCorrect: durationCorrect,
      nameCorrect: nameCorrect,
      pitchErrorDirection: pitchDirection,
      pitchErrorSeverity: pitchSeverity,
      centsDifference: centsDiff,
      durationDifference: durationDiff,
    );
  }

  // Descrição textual do erro
  String get errorDescription {
    if (pitchCorrect) return 'Perfeito!';

    switch (pitchErrorDirection) {
      case PitchErrorDirection.tooHigh:
        switch (pitchErrorSeverity) {
          case ErrorSeverity.slight:
            return 'Ligeiramente mais agudo';
          case ErrorSeverity.moderate:
            return 'Moderadamente mais agudo';
          case ErrorSeverity.severe:
            return 'Muito mais agudo';
        }
      case PitchErrorDirection.tooLow:
        switch (pitchErrorSeverity) {
          case ErrorSeverity.slight:
            return 'Ligeiramente mais grave';
          case ErrorSeverity.moderate:
            return 'Moderadamente mais grave';
          case ErrorSeverity.severe:
            return 'Muito mais grave';
        }
      case PitchErrorDirection.notSung:
        return 'Não foi detectado canto';
      case PitchErrorDirection.correct:
        return 'Perfeito!';
    }
  }
}


class AudioAnalysisData {
  final double frequency;
  final double amplitude;
  final String detectedWord;
  final double currentDuration;
  final double confidence;
  final double pitch;

  AudioAnalysisData(
      {required this.frequency,
      required this.amplitude,
      required this.detectedWord,
      required this.currentDuration,
      required this.confidence,
      required this.pitch});
}
