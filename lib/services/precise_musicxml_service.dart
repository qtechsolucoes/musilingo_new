// lib/services/precise_musicxml_service.dart
// Serviço para geração precisa de MusicXML a partir dos dados do banco

import 'package:flutter/foundation.dart';

class PreciseMusicXMLService {
  static PreciseMusicXMLService? _instance;
  static PreciseMusicXMLService get instance => _instance ??= PreciseMusicXMLService._();
  PreciseMusicXMLService._();

  /// Gera MusicXML para exercícios de solfejo
  /// Baseado na estrutura: [{"note":"C4","lyric":"Dó","duration":"quarter"}]
  String generateSolfegeMusicXML({
    required List<Map<String, dynamic>> noteSequence,
    required String keySignature,
    required String timeSignature,
    required int tempo,
    required String clef,
    String title = "Exercício de Solfejo",
  }) {
    try {
      // Calcular divisions baseado nas durações
      int divisions = _calculateDivisions(noteSequence);

      // Gerar atributos do compasso
      String clefXML = _generateClefXML(clef);
      String keyXML = _generateKeySignatureXML(keySignature);
      String timeXML = _generateTimeSignatureXML(timeSignature);
      String tempoXML = _generateTempoXML(tempo);

      // Gerar notas organizadas por compassos
      String notesXML = _generateNotesFromSolfege(noteSequence, divisions, timeSignature);

      return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <work>
    <work-title>$title</work-title>
  </work>
  <identification>
    <creator type="composer">MusiLingo</creator>
    <creator type="software">MusiLingo App - Verovio</creator>
  </identification>
  <part-list>
    <score-part id="P1">
      <part-name>Solfejo</part-name>
      <score-instrument id="P1-I1">
        <instrument-name>Voz</instrument-name>
      </score-instrument>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>$divisions</divisions>
        $keyXML
        $timeXML
        $clefXML
      </attributes>
      $tempoXML
      $notesXML
    </measure>
  </part>
</score-partwise>''';

    } catch (e) {
      debugPrint('❌ Erro ao gerar MusicXML de solfejo: $e');
      return _generateEmptyScore(title);
    }
  }

  /// Gera MusicXML para exercícios de percepção melódica
  /// Baseado na estrutura: "{"C4_quarter","D4_quarter","C4_whole"}"
  String generateMelodicMusicXML({
    required String correctSequence,
    required String keySignature,
    required String timeSignature,
    required String clef,
    required String referenceNote,
    required int tempo,
    String title = "Exercício de Percepção Melódica",
  }) {
    try {
      // Parse da sequência correta
      List<Map<String, String>> noteSequence = _parseCorrectSequence(correctSequence);

      if (noteSequence.isEmpty) {
        return _generateEmptyScore(title);
      }

      // Calcular divisions
      int divisions = _calculateDivisionsFromMelodic(noteSequence);

      // Gerar componentes
      String clefXML = _generateClefXML(clef);
      String keyXML = _generateKeySignatureXML(keySignature);
      String timeXML = _generateTimeSignatureXML(timeSignature);
      String tempoXML = _generateTempoXML(tempo);

      // Gerar notas
      String notesXML = _generateNotesFromMelodic(noteSequence, divisions, timeSignature);

      return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <work>
    <work-title>$title</work-title>
  </work>
  <identification>
    <creator type="composer">MusiLingo</creator>
    <creator type="software">MusiLingo App - Verovio</creator>
  </identification>
  <part-list>
    <score-part id="P1">
      <part-name>Melodia</part-name>
      <score-instrument id="P1-I1">
        <instrument-name>Piano</instrument-name>
      </score-instrument>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>$divisions</divisions>
        $keyXML
        $timeXML
        $clefXML
      </attributes>
      $tempoXML
      $notesXML
    </measure>
  </part>
</score-partwise>''';

    } catch (e) {
      debugPrint('❌ Erro ao gerar MusicXML melódico: $e');
      return _generateEmptyScore(title);
    }
  }

  // --- MÉTODOS AUXILIARES ---

  /// Parse da sequência de percepção melódica: "{"C4_quarter","D4_quarter"}"
  List<Map<String, String>> _parseCorrectSequence(String sequence) {
    try {
      // Remove chaves e aspas, split por vírgula
      String cleanSequence = sequence
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll('"', '')
          .trim();

      if (cleanSequence.isEmpty) return [];

      List<String> notes = cleanSequence.split(',');
      List<Map<String, String>> result = [];

      for (String noteStr in notes) {
        List<String> parts = noteStr.trim().split('_');
        if (parts.length >= 2) {
          result.add({
            'note': parts[0], // Ex: "C4"
            'duration': parts[1], // Ex: "quarter"
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Erro ao fazer parse da sequência: $e');
      return [];
    }
  }

  /// Calcula divisions para solfejo
  int _calculateDivisions(List<Map<String, dynamic>> noteSequence) {
    // Usar 4 divisions (quarter note = 4 divisions)
    // whole=16, half=8, quarter=4, eighth=2, sixteenth=1
    return 4;
  }

  /// Calcula divisions para melódica
  int _calculateDivisionsFromMelodic(List<Map<String, String>> noteSequence) {
    return 4; // Padrão
  }

  /// Gera XML das notas para solfejo
  String _generateNotesFromSolfege(
    List<Map<String, dynamic>> noteSequence,
    int divisions,
    String timeSignature
  ) {
    StringBuffer notesXML = StringBuffer();

    for (int i = 0; i < noteSequence.length; i++) {
      Map<String, dynamic> noteData = noteSequence[i];
      String note = noteData['note'] ?? 'C4';
      String duration = noteData['duration'] ?? 'quarter';
      String lyric = noteData['lyric'] ?? '';

      // Parse da nota
      Map<String, dynamic> parsedNote = _parseNoteName(note);
      int durationValue = _getDurationValue(duration, divisions);

      notesXML.write('''
      <note id="note-$i">
        <pitch>
          <step>${parsedNote['step']}</step>
          ${parsedNote['alter'] != 0 ? '<alter>${parsedNote['alter']}</alter>' : ''}
          <octave>${parsedNote['octave']}</octave>
        </pitch>
        <duration>$durationValue</duration>
        <type>$duration</type>
        ${lyric.isNotEmpty ? '<lyric number="1"><text>$lyric</text></lyric>' : ''}
      </note>''');
    }

    return notesXML.toString();
  }

  /// Gera XML das notas para percepção melódica
  String _generateNotesFromMelodic(
    List<Map<String, String>> noteSequence,
    int divisions,
    String timeSignature
  ) {
    StringBuffer notesXML = StringBuffer();

    for (int i = 0; i < noteSequence.length; i++) {
      Map<String, String> noteData = noteSequence[i];
      String note = noteData['note'] ?? 'C4';
      String duration = noteData['duration'] ?? 'quarter';

      // Parse da nota
      Map<String, dynamic> parsedNote = _parseNoteName(note);
      int durationValue = _getDurationValue(duration, divisions);

      notesXML.write('''
      <note id="note-$i">
        <pitch>
          <step>${parsedNote['step']}</step>
          ${parsedNote['alter'] != 0 ? '<alter>${parsedNote['alter']}</alter>' : ''}
          <octave>${parsedNote['octave']}</octave>
        </pitch>
        <duration>$durationValue</duration>
        <type>$duration</type>
      </note>''');
    }

    return notesXML.toString();
  }

  /// Parse do nome da nota (ex: "C4", "F#5", "Bb3")
  Map<String, dynamic> _parseNoteName(String noteName) {
    if (noteName.length < 2) {
      return {'step': 'C', 'alter': 0, 'octave': 4};
    }

    String step = noteName[0].toUpperCase();
    int alter = 0;
    String octaveStr = '';

    // Processar acidentes e oitava
    for (int i = 1; i < noteName.length; i++) {
      String char = noteName[i];
      if (char == '#') {
        alter = 1;
      } else if (char == 'b') {
        alter = -1;
      } else if (RegExp(r'\d').hasMatch(char)) {
        octaveStr += char;
      }
    }

    int octave = int.tryParse(octaveStr) ?? 4;

    return {
      'step': step,
      'alter': alter,
      'octave': octave,
    };
  }

  /// Converte duração para valor numérico
  int _getDurationValue(String duration, int divisions) {
    switch (duration.toLowerCase()) {
      case 'whole': return divisions * 4;
      case 'half': return divisions * 2;
      case 'quarter': return divisions;
      case 'eighth': return divisions ~/ 2;
      case 'sixteenth': return divisions ~/ 4;
      default: return divisions; // quarter como padrão
    }
  }

  /// Gera XML da clave
  String _generateClefXML(String clef) {
    switch (clef.toLowerCase()) {
      case 'bass':
        return '''<clef>
          <sign>F</sign>
          <line>4</line>
        </clef>''';
      case 'alto':
        return '''<clef>
          <sign>C</sign>
          <line>3</line>
        </clef>''';
      case 'treble':
      default:
        return '''<clef>
          <sign>G</sign>
          <line>2</line>
        </clef>''';
    }
  }

  /// Gera XML da armadura de clave
  String _generateKeySignatureXML(String keySignature) {
    Map<String, int> keyFifths = {
      'C': 0, 'G': 1, 'D': 2, 'A': 3, 'E': 4, 'B': 5, 'F#': 6, 'C#': 7,
      'F': -1, 'Bb': -2, 'Eb': -3, 'Ab': -4, 'Db': -5, 'Gb': -6, 'Cb': -7,
    };

    int fifths = keyFifths[keySignature] ?? 0;

    return '''<key>
      <fifths>$fifths</fifths>
      <mode>major</mode>
    </key>''';
  }

  /// Gera XML da fórmula de compasso
  String _generateTimeSignatureXML(String timeSignature) {
    List<String> parts = timeSignature.split('/');
    if (parts.length != 2) return '<time><beats>4</beats><beat-type>4</beat-type></time>';

    return '''<time>
      <beats>${parts[0]}</beats>
      <beat-type>${parts[1]}</beat-type>
    </time>''';
  }

  /// Gera XML do andamento
  String _generateTempoXML(int tempo) {
    return '''<direction placement="above">
      <direction-type>
        <metronome>
          <beat-unit>quarter</beat-unit>
          <per-minute>$tempo</per-minute>
        </metronome>
      </direction-type>
    </direction>''';
  }

  /// Gera partitura vazia em caso de erro
  String _generateEmptyScore(String title) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <work>
    <work-title>$title - Erro</work-title>
  </work>
  <part-list>
    <score-part id="P1">
      <part-name>Erro</part-name>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note>
        <rest/>
        <duration>16</duration>
        <type>whole</type>
      </note>
    </measure>
  </part>
</score-partwise>''';
  }
}