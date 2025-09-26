// lib/app/utils/musicxml_builder.dart

import 'package:flutter/material.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';

// Extensão para obter a representação hexadecimal das cores
extension ColorExtension on Color {
  static String get completedHex => '#32CD32'; // Verde Limão
  static String get errorHex => '#DC143C'; // Vermelho Carmesim
  static String get neutralHex => '#FFFFFF'; // Cor Branca para o tema escuro
  static String get highlightHex => '#FFD700'; // Amarelo Dourado
}

/// Builder aprimorado para geração robusta de MusicXML para múltiplos tipos de exercícios.
class MusicXMLBuilder {
  final String title;
  final String keySignature;
  final String timeSignature;
  final String clef;
  final int tempo;
  final List<MusicXMLMeasure> _measures = [];

  MusicXMLBuilder._({
    required this.title,
    required this.keySignature,
    required this.timeSignature,
    required this.clef,
    required this.tempo,
  });

  /// Factory para criar um builder pré-configurado para exercícios.
  factory MusicXMLBuilder.createForSolfege({
    required String title,
    required String keySignature,
    required String timeSignature,
    required String clef,
    int tempo = 120,
  }) {
    return MusicXMLBuilder._(
      title: title,
      keySignature: keySignature,
      timeSignature: timeSignature,
      clef: clef,
      tempo: tempo,
    );
  }

  MusicXMLMeasure createFirstMeasure() {
    return MusicXMLMeasure(1, hasAttributes: true);
  }

  MusicXMLBuilder addMeasure(MusicXMLMeasure measure) {
    _measures.add(measure);
    return this;
  }

  String build() {
    final measuresXml = _measures.map((m) => m.toXml(this)).join('\n');
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
  <work>
    <work-title>$title</work-title>
  </work>
  <part-list>
    <score-part id="P1">
      <part-name></part-name>
    </score-part>
  </part-list>
  <part id="P1">
    $measuresXml
  </part>
</score-partwise>
''';
  }

  // --- Mapeamentos e Helpers ---

  static int _getClefLine(String clef) {
    const clefLines = {'treble': 2, 'bass': 4, 'alto': 3, 'tenor': 4};
    return clefLines[clef.toLowerCase()] ?? 2;
  }

  static String _getClefSign(String clef) {
    const clefSigns = {'treble': 'G', 'bass': 'F', 'alto': 'C', 'tenor': 'C'};
    return clefSigns[clef.toLowerCase()] ?? 'G';
  }

  static int _getClefOctaveChange(String clef) {
    if (clef.toLowerCase() == 'treble_8vb') {
      return -1;
    }
    return 0;
  }

  static int _getKeyFifths(String key) {
    const keySignatures = {
      'C': 0,
      'G': 1,
      'D': 2,
      'A': 3,
      'E': 4,
      'B': 5,
      'F#': 6,
      'C#': 7,
      'F': -1,
      'Bb': -2,
      'Eb': -3,
      'Ab': -4,
      'Db': -5,
      'Gb': -6,
      'Cb': -7,
      'Am': 0,
      'Em': 1,
      'Bm': 2,
      'F#m': 3,
      'C#m': 4,
      'G#m': 5,
      'D#m': 6,
      'A#m': 7,
      'Dm': -1,
      'Gm': -2,
      'Cm': -3,
      'Fm': -4,
      'Bbm': -5,
      'Ebm': -6,
      'Abm': -7
    };
    return keySignatures[key] ?? 0;
  }

  static String getNoteType(String duration) {
    const durationMap = {
      'whole': 'whole',
      'half': 'half',
      'quarter': 'quarter',
      'eighth': 'eighth',
      '16th': '16th',
      '32nd': '32nd',
      '64th': '64th'
    };
    return durationMap[duration] ?? 'quarter';
  }
}

/// Representa um compasso na partitura.
class MusicXMLMeasure {
  final int number;
  final List<MusicXMLNote> notes = [];
  final bool hasAttributes;

  MusicXMLMeasure(this.number, {this.hasAttributes = false});

  void addNote(MusicXMLNote note) {
    notes.add(note);
  }

  String toXml(MusicXMLBuilder builder) {
    final notesXml = notes.map((n) => n.toXml()).join('\n');
    final attributesXml = hasAttributes
        ? '''
      <attributes>
        <divisions>16</divisions>
        <key>
          <fifths>${MusicXMLBuilder._getKeyFifths(builder.keySignature)}</fifths>
        </key>
        <time>
          <beats>${builder.timeSignature.split('/')[0]}</beats>
          <beat-type>${builder.timeSignature.split('/')[1]}</beat-type>
        </time>
        <clef>
          <sign>${MusicXMLBuilder._getClefSign(builder.clef)}</sign>
          <line>${MusicXMLBuilder._getClefLine(builder.clef)}</line>
          ${MusicXMLBuilder._getClefOctaveChange(builder.clef) != 0 ? '<clef-octave-change>${MusicXMLBuilder._getClefOctaveChange(builder.clef)}</clef-octave-change>' : ''}
        </clef>
      </attributes>
      <direction placement="above">
        <direction-type>
          <metronome>
            <beat-unit>quarter</beat-unit>
            <per-minute>${builder.tempo}</per-minute>
          </metronome>
        </direction-type>
        <sound tempo="${builder.tempo}"/>
      </direction>
    '''
        : '';

    return '''
    <measure number="$number">
      $attributesXml
      $notesXml
    </measure>
    ''';
  }
}

/// Representa uma única nota ou pausa.
class MusicXMLNote {
  final String pitch; // ex: C4, G#5, REST
  final String duration; // ex: quarter, half
  final String lyric;
  final String? color; // Cor em formato Hex (ex: #FF0000)

  MusicXMLNote({
    required this.pitch,
    required this.duration,
    this.lyric = '',
    this.color,
  });

  factory MusicXMLNote.fromNoteInfo(NoteInfo noteInfo, {String? color}) {
    return MusicXMLNote(
      pitch: noteInfo.note,
      duration: noteInfo.duration,
      lyric: noteInfo.lyric,
      color: color,
    );
  }

  factory MusicXMLNote.fromString(String noteString, {String? color}) {
    final parts = noteString.split('_');
    if (parts.length != 2) {
      throw Exception('Formato de nota inválido: $noteString');
    }
    final pitch = parts[0];
    final duration = parts[1];
    return MusicXMLNote(pitch: pitch, duration: duration, color: color);
  }

  String toXml() {
    final noteColor = color ?? ColorExtension.neutralHex;
    if (pitch.toUpperCase() == 'REST') {
      return '''
      <note>
        <rest/>
        <duration>${_getDurationDivisions()}</duration>
        <type>${MusicXMLBuilder.getNoteType(duration)}</type>
      </note>
      ''';
    }

    final RegExp noteRegex = RegExp(r'([A-G])([#b]?)(\d+)');
    final match = noteRegex.firstMatch(pitch);

    if (match == null) {
      return '';
    }

    final step = match.group(1)!;
    final alter =
        (match.group(2) == '#') ? '1' : (match.group(2) == 'b' ? '-1' : '0');
    final octave = match.group(3)!;

    final lyricXml = lyric.isNotEmpty
        ? '''
      <lyric number="1" color="$noteColor">
        <syllabic>single</syllabic>
        <text>$lyric</text>
      </lyric>
      '''
        : '';

    return '''
    <note color="$noteColor">
      <pitch>
        <step>$step</step>
        ${alter != '0' ? '<alter>$alter</alter>' : ''}
        <octave>$octave</octave>
      </pitch>
      <duration>${_getDurationDivisions()}</duration>
      <voice>1</voice>
      <type>${MusicXMLBuilder.getNoteType(duration)}</type>
      <stem>up</stem>
      $lyricXml
    </note>
    ''';
  }

  int _getDurationDivisions() {
    // Baseado em <divisions>16</divisions> (semínima = 16)
    const durationMap = {
      'whole': 64,
      'half': 32,
      'quarter': 16,
      'eighth': 8,
      '16th': 4,
      '32nd': 2,
      '64th': 1
    };
    return durationMap[duration] ?? 16;
  }
}
