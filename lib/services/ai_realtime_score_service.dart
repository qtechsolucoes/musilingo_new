// FASE 4.1: AIRealtimeScoreService - Geração de partituras em tempo real
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/verovio_service.dart';

/// Estado da geração de partitura em tempo real
enum ScoreGenerationState { idle, generating, rendering, completed, error }

/// Dados do progresso da geração
class ScoreGenerationProgress {
  final ScoreGenerationState state;
  final String currentStep;
  final double progress; // 0.0 - 1.0
  final String? partialMusicXML;
  final String? currentSVG;
  final String? errorMessage;

  const ScoreGenerationProgress({
    required this.state,
    required this.currentStep,
    required this.progress,
    this.partialMusicXML,
    this.currentSVG,
    this.errorMessage,
  });
}

class AIRealtimeScoreService {
  static AIRealtimeScoreService? _instance;
  static AIRealtimeScoreService get instance =>
      _instance ??= AIRealtimeScoreService._();
  AIRealtimeScoreService._();

  final StreamController<ScoreGenerationProgress> _progressController =
      StreamController<ScoreGenerationProgress>.broadcast();

  // Stream público para observar o progresso
  Stream<ScoreGenerationProgress> get progressStream =>
      _progressController.stream;

  /// Inicia geração de partitura em tempo real com streaming de progresso
  Future<String?> generateRealtimeScore(String prompt) async {
    try {
      // Passo 1: Preparação
      _emitProgress(
          ScoreGenerationState.generating, 'Inicializando geração...', 0.1);
      await Future.delayed(const Duration(milliseconds: 500));

      // Passo 2: Análise do prompt
      _emitProgress(ScoreGenerationState.generating,
          'Analisando comando musical...', 0.2);
      final analyzedPrompt = await _analyzePrompt(prompt);
      await Future.delayed(const Duration(milliseconds: 300));

      // Passo 3: Geração progressiva do MusicXML
      _emitProgress(
          ScoreGenerationState.generating, 'Gerando estrutura musical...', 0.3);
      final musicXML = await _generateProgressiveMusicXML(analyzedPrompt);

      if (musicXML == null) {
        _emitProgress(
            ScoreGenerationState.error, 'Falha ao gerar MusicXML', 1.0,
            errorMessage: 'Não foi possível gerar a partitura');
        return null;
      }

      // Passo 4: Renderização com Verovio
      _emitProgress(
          ScoreGenerationState.rendering, 'Renderizando partitura...', 0.8);
      await VerovioService.instance.initialize();

      final svg = await VerovioService.instance.renderMusicXML(
        musicXML,
        cacheKey: 'ai_generated_${DateTime.now().millisecondsSinceEpoch}',
        zoomLevel: 1.0, // <-- CORREÇÃO APLICADA AQUI
      );

      if (svg == null) {
        _emitProgress(ScoreGenerationState.error, 'Falha na renderização', 1.0,
            errorMessage: 'Não foi possível renderizar a partitura');
        return null;
      }

      // Passo 5: Finalização
      _emitProgress(
          ScoreGenerationState.completed, 'Partitura criada com sucesso!', 1.0,
          partialMusicXML: musicXML, currentSVG: svg);

      return musicXML;
    } catch (e) {
      _emitProgress(ScoreGenerationState.error, 'Erro na geração', 1.0,
          errorMessage: e.toString());
      return null;
    }
  }

  /// Analisa o prompt do usuário e extrai informações musicais
  Future<Map<String, dynamic>> _analyzePrompt(String prompt) async {
    // Análise básica do prompt para extrair elementos musicais
    final analysis = <String, dynamic>{
      'tempo': _extractTempo(prompt),
      'key': _extractKey(prompt),
      'timeSignature': _extractTimeSignature(prompt),
      'scale': _extractScale(prompt),
      'genre': _extractGenre(prompt),
      'instruments': _extractInstruments(prompt),
      'complexity': _extractComplexity(prompt),
    };

    debugPrint('🎵 FASE 4.1: Análise do prompt: $analysis');
    return analysis;
  }

  /// Gera MusicXML progressivamente simulando escrita em tempo real
  Future<String?> _generateProgressiveMusicXML(
      Map<String, dynamic> analysis) async {
    try {
      // Simular geração progressiva mostrando construção da partitura

      // Estrutura básica primeiro
      _emitProgress(
          ScoreGenerationState.generating, 'Criando estrutura base...', 0.4);
      await Future.delayed(const Duration(milliseconds: 400));

      // Adicionar clave e fórmula de compasso
      _emitProgress(ScoreGenerationState.generating,
          'Definindo clave e compasso...', 0.5);
      await Future.delayed(const Duration(milliseconds: 300));

      // Adicionar notas progressivamente
      _emitProgress(
          ScoreGenerationState.generating, 'Compondo melodia...', 0.6);
      await Future.delayed(const Duration(milliseconds: 500));

      _emitProgress(
          ScoreGenerationState.generating, 'Adicionando harmonia...', 0.7);
      await Future.delayed(const Duration(milliseconds: 400));

      // Gerar o MusicXML final baseado na análise
      final musicXML = _buildMusicXML(analysis);

      return musicXML;
    } catch (e) {
      debugPrint('❌ FASE 4.1: Erro na geração progressiva: $e');
      return null;
    }
  }

  /// Constrói o MusicXML final baseado na análise
  String _buildMusicXML(Map<String, dynamic> analysis) {
    final tempo = analysis['tempo'] ?? 120;
    final key = analysis['key'] ?? 'C';
    final timeSignature = analysis['timeSignature'] ?? '4/4';
    final scale = analysis['scale'] ?? 'major';

    // Gerar escala baseada na tonalidade
    final notes = _generateScaleNotes(key, scale);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <work>
    <work-title>Partitura Gerada pela IA MusiLingo</work-title>
  </work>
  <identification>
    <creator type="composer">MusiLingo IA</creator>
    <creator type="software">MusiLingo App</creator>
  </identification>
  <part-list>
    <score-part id="P1">
      <part-name>Piano</part-name>
      <score-instrument id="P1-I1">
        <instrument-name>Piano</instrument-name>
      </score-instrument>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key>
          <fifths>${_getKeyFifths(key)}</fifths>
          <mode>$scale</mode>
        </key>
        <time>
          <beats>${timeSignature.split('/')[0]}</beats>
          <beat-type>${timeSignature.split('/')[1]}</beat-type>
        </time>
        <clef>
          <sign>G</sign>
          <line>2</line>
        </clef>
      </attributes>
      <direction placement="above">
        <direction-type>
          <metronome>
            <beat-unit>quarter</beat-unit>
            <per-minute>$tempo</per-minute>
          </metronome>
        </direction-type>
      </direction>
${_generateNotesXML(notes)}
    </measure>
  </part>
</score-partwise>''';
  }

  // Métodos de análise de prompt
  int _extractTempo(String prompt) {
    final tempoRegex = RegExp(r'\b(\d+)\s*bpm\b|andante|allegro|adagio|presto');
    final match = tempoRegex.firstMatch(prompt.toLowerCase());
    if (match != null) {
      final number = match.group(1);
      if (number != null) return int.tryParse(number) ?? 120;

      // Tempos nomeados
      switch (match.group(0)) {
        case 'adagio':
          return 60;
        case 'andante':
          return 90;
        case 'allegro':
          return 140;
        case 'presto':
          return 180;
      }
    }
    return 120;
  }

  String _extractKey(String prompt) {
    final keyRegex = RegExp(r'\b([A-G][#b]?)\s*(maior|minor|major)\b');
    final match = keyRegex.firstMatch(prompt);
    return match?.group(1) ?? 'C';
  }

  String _extractTimeSignature(String prompt) {
    final timeRegex = RegExp(r'\b(\d+/\d+)\b');
    final match = timeRegex.firstMatch(prompt);
    return match?.group(1) ?? '4/4';
  }

  String _extractScale(String prompt) {
    if (prompt.toLowerCase().contains('menor') ||
        prompt.toLowerCase().contains('minor')) {
      return 'minor';
    }
    return 'major';
  }

  String _extractGenre(String prompt) {
    final genres = ['rock', 'jazz', 'classical', 'pop', 'blues', 'folk'];
    for (final genre in genres) {
      if (prompt.toLowerCase().contains(genre)) return genre;
    }
    return 'classical';
  }

  List<String> _extractInstruments(String prompt) {
    final instruments = ['piano', 'violin', 'guitar', 'flute', 'trumpet'];
    final found = <String>[];
    for (final instrument in instruments) {
      if (prompt.toLowerCase().contains(instrument)) found.add(instrument);
    }
    return found.isNotEmpty ? found : ['piano'];
  }

  String _extractComplexity(String prompt) {
    if (prompt.toLowerCase().contains('simples') ||
        prompt.toLowerCase().contains('básico')) {
      return 'simple';
    } else if (prompt.toLowerCase().contains('complexo') ||
        prompt.toLowerCase().contains('avançado')) {
      return 'complex';
    }
    return 'intermediate';
  }

  List<String> _generateScaleNotes(String key, String scale) {
    // Escalas básicas para diferentes tonalidades
    final majorScales = {
      'C': ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
      'G': ['G', 'A', 'B', 'C', 'D', 'E', 'F#'],
      'D': ['D', 'E', 'F#', 'G', 'A', 'B', 'C#'],
      'A': ['A', 'B', 'C#', 'D', 'E', 'F#', 'G#'],
      'F': ['F', 'G', 'A', 'Bb', 'C', 'D', 'E'],
    };

    final notes = majorScales[key] ?? majorScales['C']!;

    if (scale == 'minor') {
      // Transformar para escala menor natural (abaixar 3ª, 6ª e 7ª graus)
      return notes; // Simplificado para este exemplo
    }

    return notes;
  }

  String _generateNotesXML(List<String> notes) {
    String xml = '';

    for (final note in notes.take(4)) {
      // Apenas 4 notas para caber no 4/4
      xml += '''
      <note>
        <pitch>
          <step>${note[0]}</step>
          ${note.length > 1 ? '<alter>${note.contains('#') ? '1' : '-1'}</alter>' : ''}
          <octave>4</octave>
        </pitch>
        <duration>4</duration>
        <type>quarter</type>
      </note>''';
    }

    return xml;
  }

  int _getKeyFifths(String key) {
    // Círculo das quintas simplificado
    final fifths = {
      'C': 0,
      'G': 1,
      'D': 2,
      'A': 3,
      'E': 4,
      'B': 5,
      'F': -1,
      'Bb': -2,
      'Eb': -3,
      'Ab': -4,
      'Db': -5
    };
    return fifths[key] ?? 0;
  }

  void _emitProgress(ScoreGenerationState state, String step, double progress,
      {String? partialMusicXML, String? currentSVG, String? errorMessage}) {
    final progressData = ScoreGenerationProgress(
      state: state,
      currentStep: step,
      progress: progress,
      partialMusicXML: partialMusicXML,
      currentSVG: currentSVG,
      errorMessage: errorMessage,
    );

    _progressController.add(progressData);
    debugPrint('🎵 FASE 4.1: $step (${(progress * 100).round()}%)');
  }

  void dispose() {
    _progressController.close();
  }
}
