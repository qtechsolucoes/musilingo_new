// Conversor MusicXML para Canvas - Converte MusicXML em estruturas Canvas
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/canvas_music_renderer.dart';

/// Conversor inteligente de MusicXML para Canvas
class MusicXMLToCanvasConverter {
  static const Map<String, String> _pitchToSolfege = {
    'C': 'Dó',
    'D': 'Ré',
    'E': 'Mi',
    'F': 'Fá',
    'G': 'Sol',
    'A': 'Lá',
    'B': 'Si',
  };

  /// Converte MusicXML para lista de notas Canvas
  static List<MusicalNote> convertMusicXMLToNotes(String musicXML) {
    final notes = <MusicalNote>[];

    try {
      // Extrair notas do MusicXML usando regex
      final noteRegex = RegExp(
        r'<note[^>]*id="([^"]*)"[^>]*>.*?<step>([A-G])</step>.*?<octave>(\d)</octave>.*?<duration>(\d+)</duration>.*?<lyric[^>]*><text>([^<]+)</text></lyric>.*?</note>',
        dotAll: true,
        multiLine: true,
      );

      final matches = noteRegex.allMatches(musicXML);

      for (int i = 0; i < matches.length; i++) {
        final match = matches.elementAt(i);

        final noteId = match.group(1) ?? 'note-$i';
        final step = match.group(2) ?? 'C';
        final octave = match.group(3) ?? '4';
        final durationStr = match.group(4) ?? '4';
        final lyric = match.group(5) ?? _pitchToSolfege[step] ?? step;

        final pitch = '$step$octave';
        final duration = _convertDuration(int.parse(durationStr));

        notes.add(MusicalNote(
          pitch: pitch,
          lyric: lyric,
          duration: duration,
          noteId: noteId,
        ));
      }

      // Se não encontrou notas no MusicXML, usar sequência padrão de solfejo
      if (notes.isEmpty) {
        return _generateDefaultSolfegeSequence();
      }

      return notes;
    } catch (e) {
      debugPrint('❌ Erro ao converter MusicXML: $e');
      return _generateDefaultSolfegeSequence();
    }
  }

  /// Gera sequência padrão de solfejo quando MusicXML falha
  static List<MusicalNote> _generateDefaultSolfegeSequence() {
    debugPrint('🎵 Gerando sequência padrão de solfejo');

    return [
      const MusicalNote(pitch: 'C4', lyric: 'Dó', duration: 0.25, noteId: 'note-0'),
      const MusicalNote(pitch: 'D4', lyric: 'Ré', duration: 0.25, noteId: 'note-1'),
      const MusicalNote(pitch: 'E4', lyric: 'Mi', duration: 0.5, noteId: 'note-2'),
      const MusicalNote(pitch: 'F4', lyric: 'Fá', duration: 0.25, noteId: 'note-3'),
      const MusicalNote(pitch: 'G4', lyric: 'Sol', duration: 0.25, noteId: 'note-4'),
      const MusicalNote(pitch: 'A4', lyric: 'Lá', duration: 0.5, noteId: 'note-5'),
      const MusicalNote(pitch: 'B4', lyric: 'Si', duration: 0.25, noteId: 'note-6'),
      const MusicalNote(pitch: 'C5', lyric: 'Dó', duration: 1.0, noteId: 'note-7'),
    ];
  }

  /// Converte duração do MusicXML para valor decimal
  static double _convertDuration(int divisions) {
    // Assumindo divisions=4 como padrão (semínima)
    switch (divisions) {
      case 16: return 1.0;    // Semibreve
      case 12: return 0.75;   // Mínima pontuada
      case 8: return 0.5;     // Mínima
      case 6: return 0.375;   // Semínima pontuada
      case 4: return 0.25;    // Semínima
      case 3: return 0.1875;  // Colcheia pontuada
      case 2: return 0.125;   // Colcheia
      case 1: return 0.0625;  // Semicolcheia
      default: return 0.25;   // Padrão semínima
    }
  }

  /// Cria sequência personalizada para exercício específico
  static List<MusicalNote> createCustomSequence({
    required String sequenceType,
    int noteCount = 8,
  }) {
    switch (sequenceType) {
      case 'scale_ascending':
        return _createAscendingScale(noteCount);
      case 'scale_descending':
        return _createDescendingScale(noteCount);
      case 'arpeggios':
        return _createArpeggios();
      case 'intervals':
        return _createIntervals();
      default:
        return _generateDefaultSolfegeSequence();
    }
  }

  static List<MusicalNote> _createAscendingScale(int noteCount) {
    final pitches = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'];
    final lyrics = ['Dó', 'Ré', 'Mi', 'Fá', 'Sol', 'Lá', 'Si', 'Dó'];

    return List.generate(
      math.min(noteCount, pitches.length),
      (i) => MusicalNote(
        pitch: pitches[i],
        lyric: lyrics[i],
        duration: 0.25,
        noteId: 'note-$i',
      ),
    );
  }

  static List<MusicalNote> _createDescendingScale(int noteCount) {
    final pitches = ['C5', 'B4', 'A4', 'G4', 'F4', 'E4', 'D4', 'C4'];
    final lyrics = ['Dó', 'Si', 'Lá', 'Sol', 'Fá', 'Mi', 'Ré', 'Dó'];

    return List.generate(
      math.min(noteCount, pitches.length),
      (i) => MusicalNote(
        pitch: pitches[i],
        lyric: lyrics[i],
        duration: 0.25,
        noteId: 'note-$i',
      ),
    );
  }

  static List<MusicalNote> _createArpeggios() {
    return [
      const MusicalNote(pitch: 'C4', lyric: 'Dó', duration: 0.25, noteId: 'note-0'),
      const MusicalNote(pitch: 'E4', lyric: 'Mi', duration: 0.25, noteId: 'note-1'),
      const MusicalNote(pitch: 'G4', lyric: 'Sol', duration: 0.25, noteId: 'note-2'),
      const MusicalNote(pitch: 'C5', lyric: 'Dó', duration: 0.5, noteId: 'note-3'),
      const MusicalNote(pitch: 'G4', lyric: 'Sol', duration: 0.25, noteId: 'note-4'),
      const MusicalNote(pitch: 'E4', lyric: 'Mi', duration: 0.25, noteId: 'note-5'),
      const MusicalNote(pitch: 'C4', lyric: 'Dó', duration: 0.5, noteId: 'note-6'),
    ];
  }

  static List<MusicalNote> _createIntervals() {
    return [
      const MusicalNote(pitch: 'C4', lyric: 'Dó', duration: 0.5, noteId: 'note-0'),
      const MusicalNote(pitch: 'E4', lyric: 'Mi', duration: 0.5, noteId: 'note-1'),
      const MusicalNote(pitch: 'D4', lyric: 'Ré', duration: 0.5, noteId: 'note-2'),
      const MusicalNote(pitch: 'F4', lyric: 'Fá', duration: 0.5, noteId: 'note-3'),
      const MusicalNote(pitch: 'E4', lyric: 'Mi', duration: 0.5, noteId: 'note-4'),
      const MusicalNote(pitch: 'G4', lyric: 'Sol', duration: 0.5, noteId: 'note-5'),
      const MusicalNote(pitch: 'C4', lyric: 'Dó', duration: 1.0, noteId: 'note-6'),
    ];
  }
}