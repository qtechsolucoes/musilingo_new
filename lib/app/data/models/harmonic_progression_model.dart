// lib/app/data/models/harmonic_progression_model.dart

class HarmonicProgression {
  final int id;
  final String title;
  final int difficulty;
  final String key;

  // Lista de acordes, onde cada acorde é uma string de notas
  // Ex: ['C4 E4 G4', 'F4 A4 C5', 'G4 B4 D5', 'C4 E4 G4']
  final List<List<String>> progression;

  // Opções de resposta em texto
  final List<String> options;

  // A resposta correta
  final String correctAnswer;

  HarmonicProgression({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.key,
    required this.progression,
    required this.options,
    required this.correctAnswer,
  });

  factory HarmonicProgression.fromMap(Map<String, dynamic> map) {
    // Converte a lista de strings do Supabase (ex: "C4 E4 G4")
    // numa lista de listas de strings (ex: ['C4', 'E4', 'G4'])
    final chordsAsListOfStrings = List<String>.from(map['progression'] ?? []);
    final parsedProgression = chordsAsListOfStrings
        .map((chordString) => chordString.split(' ').toList())
        .toList();

    return HarmonicProgression(
      id: map['id'],
      title: map['title'] ?? 'Exercício de Progressão',
      difficulty: map['difficulty'] ?? 1,
      key: map['key'] ?? 'C Major',
      progression: parsedProgression,
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correct_answer'] ?? '',
    );
  }
}
