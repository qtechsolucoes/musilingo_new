// lib/app/data/models/melodic_exercise_model.dart

class MelodicExercise {
  final int id;
  final String title;
  final int difficulty;
  final String clef;
  final String keySignature;
  final String timeSignature;
  final String referenceNote;
  final String musicXml;
  final List<String> correctSequence;
  final int tempo; // ADICIONADO

  // --- ALTERAÇÃO INÍCIO ---
  // Adicionamos as paletas ao modelo.
  final List<String> notePalette;
  final List<String> figurePalette; // Lista de chaves (ex: 'quarter', 'half')
  // --- ALTERAÇÃO FIM ---

  MelodicExercise({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.clef,
    required this.keySignature,
    required this.timeSignature,
    required this.referenceNote,
    required this.musicXml,
    required this.correctSequence,
    // --- ALTERAÇÃO INÍCIO ---
    required this.notePalette,
    required this.figurePalette,
    required this.tempo, // ADICIONADO
    // --- ALTERAÇÃO FIM ---
  });

  factory MelodicExercise.fromMap(Map<String, dynamic> map) {
    // Paletas padrão caso a informação não venha do banco de dados
    final defaultNotePalette = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"];
    final defaultFigurePalette = ['quarter', 'half', 'eighth'];

    return MelodicExercise(
      id: map['id'],
      title: map['title'] ?? '',
      difficulty: map['difficulty'] ?? 1,
      clef: map['clef'] ?? 'treble',
      keySignature: map['key_signature'] ?? 'C',
      timeSignature: map['time_signature'] ?? '4/4',
      referenceNote: map['reference_note'] ?? 'C4',
      musicXml: map['music_xml'] ?? '',
      correctSequence: List<String>.from(map['correct_sequence'] ?? []),
      // --- ALTERAÇÃO INÍCIO ---
      // Lendo as paletas do mapa, com um fallback para os valores padrão.
      notePalette: List<String>.from(map['note_palette'] ?? defaultNotePalette),
      figurePalette:
          List<String>.from(map['figure_palette'] ?? defaultFigurePalette),
      tempo: map['tempo'] ?? 100,
      // --- ALTERAÇÃO FIM ---
    );
  }
}
