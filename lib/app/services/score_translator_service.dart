// lib/app/services/score_translator_service.dart

class ScoreTranslatorService {
  // Mapeia nossas durações simples para os tipos do MusicXML
  final Map<String, String> _durationMap = {
    'w': 'whole', // semibreve
    'h': 'half', // mínima
    'q': 'quarter', // semínima
    'e': 'eighth', // colcheia
    's': '16th', // semicolcheia
  };

  // Mapeia nossas durações para valores numéricos (base: semínima = 1.0)
  final Map<String, double> _durationValues = {
    'w': 4.0,
    'h': 2.0,
    'q': 1.0,
    'e': 0.5,
    's': 0.25,
  };

  // Mapeia nossas claves para os sinais e linhas do MusicXML
  final Map<String, Map<String, String>> _clefMap = {
    'treble': {'sign': 'G', 'line': '2'},
    'bass': {'sign': 'F', 'line': '4'},
    'alto': {'sign': 'C', 'line': '3'},
    'tenor': {'sign': 'C', 'line': '4'},
  };

  /// Converte um objeto JSON de partitura em uma string MusicXML, adicionando barras de compasso.
  String convertJsonToMusicXml(Map<String, dynamic> scoreJson) {
    try {
      final clef = scoreJson['clef'] ?? 'treble';
      final timeSignature = (scoreJson['timeSignature'] ?? '4/4').split('/');
      final notes = scoreJson['notes'] as List;

      final clefSign = _clefMap[clef]?['sign'] ?? 'G';
      final clefLine = _clefMap[clef]?['line'] ?? '2';
      final beats = int.tryParse(timeSignature[0]) ?? 4;
      final beatType = int.tryParse(timeSignature[1]) ?? 4;

      // Calcula a capacidade total de um compasso (ex: 4/4 = 4.0 semínimas)
      final measureCapacity = beats * (4.0 / beatType);

      var xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1">
      <part-name>Music</part-name>
    </score-part>
  </part-list>
  <part id="P1">
''';

      double currentMeasureBeats = 0;
      int measureCount = 1;

      // Abre o primeiro compasso e adiciona os atributos
      xml += '''
    <measure number="$measureCount">
      <attributes>
        <divisions>1</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>$beats</beats><beat-type>$beatType</beat-type></time>
        <clef><sign>$clefSign</sign><line>$clefLine</line></clef>
      </attributes>
''';

      for (var noteData in notes) {
        final note = Map<String, dynamic>.from(noteData);
        final durationStr = note['duration'] as String;
        final noteValue = _durationValues[durationStr] ?? 0;

        // Se a nota não cabe no compasso atual, fecha o antigo e abre um novo
        if (currentMeasureBeats + noteValue > measureCapacity) {
          xml += '    </measure>\n';
          measureCount++;
          xml += '    <measure number="$measureCount">\n';
          currentMeasureBeats = 0;
        }

        xml += _noteToXml(note);
        currentMeasureBeats += noteValue;
      }

      // Fecha o último compasso
      xml += '''
    </measure>
  </part>
</score-partwise>
''';

      return xml;
    } catch (e) {
      return _buildErrorXml();
    }
  }

  /// Converte um único objeto de nota em sua representação MusicXML.
  String _noteToXml(Map<String, dynamic> note) {
    final pitch = note['pitch'] as String;
    final duration = note['duration'] as String;
    final type = _durationMap[duration] ?? 'quarter';

    if (pitch.toUpperCase() == 'REST') {
      return '      <note><rest/><duration>1</duration><type>$type</type></note>\n';
    } else {
      final step = pitch.substring(0, 1).toUpperCase();
      final alterValue =
          pitch.contains('#') ? '1' : (pitch.contains('b') ? '-1' : '0');
      final octave = pitch.substring(pitch.length - 1);

      return '''
      <note>
        <pitch>
          <step>$step</step>
          ${alterValue != '0' ? '<alter>$alterValue</alter>' : ''}
          <octave>$octave</octave>
        </pitch>
        <duration>1</duration>
        <type>$type</type>
      </note>
''';
    }
  }

  String _buildErrorXml() {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Error</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>1</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note>
        <pitch><step>C</step><octave>4</octave></pitch>
        <duration>4</duration>
        <type>whole</type>
        <notehead>none</notehead>
        <lyric>
          <text>Erro ao gerar a partitura</text>
        </lyric>
      </note>
    </measure>
  </part>
</score-partwise>
''';
  }
}
