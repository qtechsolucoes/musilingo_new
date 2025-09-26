// lib/app/services/midi_playback_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

// Classe auxiliar para converter nomes de notas para MIDI
class _MusicUtils {
  static const Map<String, int> _noteValues = {
    'C': 0,
    'C#': 1,
    'Db': 1,
    'D': 2,
    'D#': 3,
    'Eb': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'Gb': 6,
    'G': 7,
    'G#': 8,
    'Ab': 8,
    'A': 9,
    'A#': 10,
    'Bb': 10,
    'B': 11
  };

  static int noteNameToMidi(String noteName) {
    if (noteName.toUpperCase().contains("REST")) return 0;

    final notePart = noteName.replaceAll(RegExp(r'[0-9]'), '');
    final octavePart = noteName.replaceAll(RegExp(r'[^0-9]'), '');

    if (octavePart.isEmpty || !_noteValues.containsKey(notePart)) return 60;

    final octave = int.parse(octavePart);
    return _noteValues[notePart]! + (octave + 1) * 12;
  }
}

class MidiPlaybackService {
  final _midiPro = MidiPro();
  int? _soundfontId;
  bool _isReady = false;

  MidiPlaybackService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      const sfPath = 'assets/sf2/GeneralUserGS.sf2';
      _soundfontId =
          await _midiPro.loadSoundfont(path: sfPath, bank: 0, program: 0);
      _isReady = true;
    } catch (e) {
      debugPrint("Erro ao inicializar o MidiPlaybackService: $e");
    }
  }

  /// Toca uma sequência de notas e notifica o progresso através de callbacks.
  Future<void> playNoteSequence({
    required List<Map<String, dynamic>> notes,
    required Function(int noteIndex) onNotePlayed,
    required VoidCallback onPlaybackComplete,
  }) async {
    if (!_isReady || _soundfontId == null) {
      debugPrint("Serviço de MIDI não está pronto.");
      onPlaybackComplete(); // Notifica a conclusão mesmo se falhar
      return;
    }

    // Duração de uma semínima em milissegundos (baseado em 120 BPM)
    const quarterNoteDuration = 500;

    for (int i = 0; i < notes.length; i++) {
      final noteData = notes[i];
      final pitch = noteData['pitch'] as String?;
      final duration = noteData['duration'] as String?;

      if (pitch == null || duration == null) continue;

      // Notifica a UI sobre qual nota está prestes a ser tocada
      onNotePlayed(i);

      double durationMultiplier = 1.0;
      switch (duration) {
        case 'w':
          durationMultiplier = 4.0;
          break;
        case 'h':
          durationMultiplier = 2.0;
          break;
        case 'q':
          durationMultiplier = 1.0;
          break;
        case 'e':
          durationMultiplier = 0.5;
          break;
        case 's':
          durationMultiplier = 0.25;
          break;
      }

      final midiNote = _MusicUtils.noteNameToMidi(pitch);
      final noteDuration = (quarterNoteDuration * durationMultiplier).round();

      if (midiNote != 0) {
        // Não toca pausas
        _midiPro.playNote(
            sfId: _soundfontId!, channel: 0, key: midiNote, velocity: 127);
      }

      await Future.delayed(Duration(milliseconds: noteDuration));

      if (midiNote != 0) {
        _midiPro.stopNote(sfId: _soundfontId!, channel: 0, key: midiNote);
      }
    }

    // Notifica a UI que a reprodução terminou
    onPlaybackComplete();
  }
}
