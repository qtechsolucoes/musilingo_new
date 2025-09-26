// lib/app/data/models/harmonic_exercise_model.dart

class HarmonicExercise {
  final int id;
  final String title;
  final int difficulty;

  final List<String> chordNotes;
  final List<String> options;
  final String correctAnswer;

  // NOVOS CAMPOS ADICIONADOS
  final String inversion;
  final String playbackStyle;

  HarmonicExercise({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.chordNotes,
    required this.options,
    required this.correctAnswer,
    required this.inversion,
    required this.playbackStyle,
  });

  factory HarmonicExercise.fromMap(Map<String, dynamic> map) {
    return HarmonicExercise(
      id: map['id'],
      title: map['title'] ?? 'Exercício de Harmonia',
      difficulty: map['difficulty'] ?? 1,
      chordNotes: List<String>.from(map['chord_notes'] ?? []),
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correct_answer'] ?? '',
      // Lendo os novos campos do mapa de dados
      inversion: map['inversion'] ?? 'fundamental',
      playbackStyle: map['playback_style'] ?? 'bloco',
    );
  }
}
