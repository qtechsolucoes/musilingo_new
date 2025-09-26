// lib/features/practice/presentation/viewmodel/melodic_exercise_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/features/practice/presentation/widgets/melodic_input_panel.dart';
import 'package:musilingo/services/precise_musicxml_service.dart';

class MelodicExerciseViewModel extends ChangeNotifier {
  final MelodicExercise exercise;

  List<String> _userSequence = [];
  bool _isVerified = false;
  int _octaveOffset = 0;
  AccidentalType _currentAccidental = AccidentalType.none;
  late String _selectedNote;
  late String _selectedFigure;

  MelodicExerciseViewModel({required this.exercise}) {
    _selectedFigure = 'quarter';
    _selectedNote = _getInitialNoteName();
  }

  // --- GETTERS ---
  List<String> get userSequence => _userSequence;
  bool get isVerified => _isVerified;
  AccidentalType get currentAccidental => _currentAccidental;
  String get selectedNote => _selectedNote;
  String get selectedFigure => _selectedFigure;

  List<String> get _baseNotePalette {
    final originalPalette = exercise.notePalette;
    if (originalPalette.length < 2) {
      return originalPalette;
    }
    final firstNote = originalPalette.first.replaceAll(RegExp(r'[0-9]'), '');
    final lastNote = originalPalette.last.replaceAll(RegExp(r'[0-9]'), '');
    if (firstNote == 'C' && lastNote == 'B') {
      return originalPalette;
    }
    return originalPalette.sublist(0, originalPalette.length - 1);
  }

  int get displayOctave => _getInitialOctave() + _octaveOffset;

  List<String> get octaveAdjustedNotePalette {
    return _baseNotePalette
        .map((note) => '${note.replaceAll(RegExp(r'[0-9]'), '')}$displayOctave')
        .toList();
  }

  // FASE 4.6: GETTER DO MUSICXML USANDO PreciseMusicXMLService
  String get musicXml {
    try {
      return _buildPreciseMusicXML();
    } catch (e) {
      debugPrint('❌ FASE 4.6: Erro ao gerar MusicXML melódico: $e');
      return _buildFallbackMusicXML();
    }
  }

  // FASE 4.6: Método principal usando PreciseMusicXMLService
  String _buildPreciseMusicXML() {
    try {
      // Se o musicXml do exercício não está vazio, usar primeiro
      if (exercise.musicXml.isNotEmpty) {
        debugPrint('✅ FASE 4.6: Usando MusicXML do banco de dados');
        return exercise.musicXml;
      }

      // Se há uma sequência correta, usar ela
      if (exercise.correctSequence.isNotEmpty) {
        debugPrint('🎵 FASE 4.6: Gerando MusicXML a partir de correct_sequence');

        // Converter correct_sequence para o formato esperado pelo serviço
        String sequenceString = exercise.correctSequence.join(',');
        if (!sequenceString.startsWith('{')) {
          sequenceString = '{$sequenceString}';
        }

        final musicXML = PreciseMusicXMLService.instance.generateMelodicMusicXML(
          correctSequence: sequenceString,
          keySignature: exercise.keySignature,
          timeSignature: exercise.timeSignature,
          clef: exercise.clef,
          referenceNote: exercise.referenceNote,
          tempo: exercise.tempo,
          title: exercise.title,
        );

        if (musicXML.isNotEmpty && musicXML != _buildFallbackMusicXML()) {
          return musicXML;
        }
      }

      // Se temos userSequence (notas que o usuário colocou), gerar a partir delas
      if (_userSequence.isNotEmpty) {
        debugPrint('🎵 FASE 4.6: Gerando MusicXML a partir de user sequence');

        String userSequenceString = _userSequence.join(',');
        if (!userSequenceString.startsWith('{')) {
          userSequenceString = '{$userSequenceString}';
        }

        final musicXML = PreciseMusicXMLService.instance.generateMelodicMusicXML(
          correctSequence: userSequenceString,
          keySignature: exercise.keySignature,
          timeSignature: exercise.timeSignature,
          clef: exercise.clef,
          referenceNote: exercise.referenceNote,
          tempo: exercise.tempo,
          title: '${exercise.title} - Sua Resposta',
        );

        if (musicXML.isNotEmpty && musicXML != _buildFallbackMusicXML()) {
          return musicXML;
        }
      }

      // Fallback para compasso vazio
      debugPrint('⚠️ FASE 4.6: Gerando partitura vazia para exercício melódico');
      return PreciseMusicXMLService.instance.generateMelodicMusicXML(
        correctSequence: '{}',
        keySignature: exercise.keySignature,
        timeSignature: exercise.timeSignature,
        clef: exercise.clef,
        referenceNote: exercise.referenceNote,
        tempo: exercise.tempo,
        title: exercise.title,
      );

    } catch (e) {
      debugPrint('❌ FASE 4.6: Erro na geração precisa melódica: $e');
      return _buildFallbackMusicXML();
    }
  }


  String _buildFallbackMusicXML() {
    // Fallback simples em caso de erro
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Music</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>1</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
    </measure>
  </part>
</score-partwise>''';
  }


  String _getInitialNoteName() {
    return exercise.notePalette.isNotEmpty
        ? exercise.notePalette.first.replaceAll(RegExp(r'[0-9]'), '')
        : 'C';
  }

  int _getInitialOctave() {
    return exercise.notePalette.isNotEmpty
        ? int.tryParse(
                exercise.notePalette.first.replaceAll(RegExp(r'[^0-9]'), '')) ??
            4
        : 4;
  }

  void onNoteSelected(String note) {
    _selectedNote = note.replaceAll(RegExp(r'[0-9]'), '');
    notifyListeners();
  }

  void onFigureSelected(String figure) {
    _selectedFigure = figure;
    notifyListeners();
  }

  void onAccidentalSelected(AccidentalType type) {
    _currentAccidental =
        (_currentAccidental == type) ? AccidentalType.none : type;
    notifyListeners();
  }

  void onOctaveUp() {
    if (_octaveOffset < 2) {
      _octaveOffset++;
      notifyListeners();
    }
  }

  void onOctaveDown() {
    if (_octaveOffset > -2) {
      _octaveOffset--;
      notifyListeners();
    }
  }

  void addNoteToSequence() {
    if (_isVerified) {
      return;
    }

    String noteNameOnly = _selectedNote;
    String accidentalSign = "";
    if (_currentAccidental == AccidentalType.sharp) {
      accidentalSign = "#";
    } else if (_currentAccidental == AccidentalType.flat) {
      accidentalSign = "b";
    }

    final finalNoteName = '$noteNameOnly$accidentalSign$displayOctave';
    _userSequence.add("${finalNoteName}_$_selectedFigure");
    _currentAccidental = AccidentalType.none;
    notifyListeners();
  }

  void addRest() {
    if (_isVerified) {
      return;
    }
    _userSequence.add("rest_$_selectedFigure");
    notifyListeners();
  }

  void removeLastNote() {
    if (_isVerified || _userSequence.isEmpty) {
      return;
    }
    _userSequence.removeLast();
    notifyListeners();
  }

  bool verifyAnswer() {
    _isVerified = true;
    notifyListeners(); // Notifica a UI para reconstruir o musicXml com as cores

    // Comparação simples de listas sem usar collection
    if (_userSequence.length != exercise.correctSequence.length) return false;
    for (int i = 0; i < _userSequence.length; i++) {
      if (_userSequence[i] != exercise.correctSequence[i]) return false;
    }
    return true;
  }

  void reset() {
    _userSequence = [];
    _isVerified = false;
    _octaveOffset = 0;
    _selectedFigure = 'quarter';
    _selectedNote = _getInitialNoteName();
    _currentAccidental = AccidentalType.none;
    notifyListeners();
  }
}
