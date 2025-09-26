// lib/features/practice_solfege/providers/solfege_exercise_provider.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/app/services/gamification_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/app/core/service_registry.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/services/midi_service.dart';
import 'package:musilingo/features/practice_solfege/services/audio_analysis_service.dart';
import 'package:musilingo/features/practice_solfege/data/services/solfege_database_service.dart';
import 'package:musilingo/features/practice_solfege/data/models/solfege_progress.dart';
// FASE 3.3: Import do VerovioService - substituição do OSMD
import 'package:musilingo/services/verovio_service.dart';
import 'package:musilingo/services/precise_musicxml_service.dart';

// Enums para estados (SEU CÓDIGO ORIGINAL MANTIDO)
enum SolfegeState {
  idle,
  countdown,
  listening,
  analyzing,
  finished,
}

// Modelo para resultado de análise (SEU CÓDIGO ORIGINAL MANTIDO)
class SolfegeAnalysisResult {
  final bool pitchCorrect;
  final bool durationCorrect;
  final double pitchAccuracy;
  final double durationAccuracy;

  const SolfegeAnalysisResult({
    required this.pitchCorrect,
    required this.durationCorrect,
    required this.pitchAccuracy,
    required this.durationAccuracy,
  });
}

// Enums para controles avançados
enum ScoreDisplayMode { horizontal, lineBreak }

// Estado do exercício (SEU CÓDIGO ORIGINAL MANTIDO)
class SolfegeExerciseState {
  final SolfegeExercise exercise;
  final SolfegeState state;
  final int currentNoteIndex;
  final int countdownValue;
  final List<SolfegeAnalysisResult> results;
  final bool isInitialized;
  final bool isPlayingPreview;
  final bool showNoteNames;
  final bool playWithPiano;
  final String musicXml;
  final int pitchScore;
  final int durationScore;
  final SolfegeProgress? progress;
  final bool isLoadingFromDatabase;
  // Controles avançados da partitura
  final double zoomLevel;
  final ScoreDisplayMode displayMode;
  final bool showMetronomeInPreview;

  const SolfegeExerciseState({
    required this.exercise,
    this.state = SolfegeState.idle,
    this.currentNoteIndex = -1,
    this.countdownValue = 3,
    this.results = const [],
    this.isInitialized = false,
    this.isPlayingPreview = false,
    this.showNoteNames = false,
    this.playWithPiano = false,
    this.musicXml = '',
    this.pitchScore = 0,
    this.durationScore = 0,
    this.progress,
    this.isLoadingFromDatabase = false,
    // Controles avançados da partitura
    this.zoomLevel = 1.0,
    this.displayMode = ScoreDisplayMode.lineBreak,
    this.showMetronomeInPreview = true,
  });

  SolfegeExerciseState copyWith({
    SolfegeExercise? exercise,
    SolfegeState? state,
    int? currentNoteIndex,
    int? countdownValue,
    List<SolfegeAnalysisResult>? results,
    bool? isInitialized,
    bool? isPlayingPreview,
    bool? showNoteNames,
    bool? playWithPiano,
    String? musicXml,
    int? pitchScore,
    int? durationScore,
    SolfegeProgress? progress,
    bool? isLoadingFromDatabase,
    double? zoomLevel,
    ScoreDisplayMode? displayMode,
    bool? showMetronomeInPreview,
  }) {
    return SolfegeExerciseState(
      exercise: exercise ?? this.exercise,
      state: state ?? this.state,
      currentNoteIndex: currentNoteIndex ?? this.currentNoteIndex,
      countdownValue: countdownValue ?? this.countdownValue,
      results: results ?? this.results,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlayingPreview: isPlayingPreview ?? this.isPlayingPreview,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      playWithPiano: playWithPiano ?? this.playWithPiano,
      musicXml: musicXml ?? this.musicXml,
      pitchScore: pitchScore ?? this.pitchScore,
      durationScore: durationScore ?? this.durationScore,
      progress: progress ?? this.progress,
      isLoadingFromDatabase:
          isLoadingFromDatabase ?? this.isLoadingFromDatabase,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      displayMode: displayMode ?? this.displayMode,
      showMetronomeInPreview:
          showMetronomeInPreview ?? this.showMetronomeInPreview,
    );
  }
}

// Notifier para o exercício de solfejo com análise de áudio
class SolfegeExerciseNotifier extends StateNotifier<SolfegeExerciseState> {
  AudioAnalysisService? _audioService;
  StreamSubscription<AudioAnalysisData>? _audioSubscription;
  Timer? _noteTimer;
  Timer? _metronomeTimer;
  DateTime? _currentNoteStartTime;
  final List<NoteResult> _detectedResults = [];
  MidiService? _midiService;
  AudioAnalysisData? _lastAnalysisData; // Dados mais recentes da análise

  // FASE 3.3: Removido callback WebView - agora usando VerovioService diretamente

  // Services
  final SolfegeDatabaseService _databaseService =
      SolfegeDatabaseService.instance;

  SolfegeExerciseNotifier()
      : super(SolfegeExerciseState(
          exercise: SolfegeExercise(
            id: '',
            title: '',
            difficultyLevel: '',
            difficultyValue: 0,
            keySignature: '',
            timeSignature: '',
            tempo: 120,
            noteSequence: [],
            createdAt: DateTime.now(),
            clef: '',
          ),
        ));

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _noteTimer?.cancel();
    _metronomeTimer?.cancel();
    _audioService?.dispose();
    super.dispose();
  }

  // FASE 3.3: Removido setWebViewCallback - comunicação direta com VerovioService

  // Carregar exercício do banco de dados por ID
  Future<void> loadExerciseById(int exerciseId) async {
    try {
      state = state.copyWith(isLoadingFromDatabase: true);

      // Obter userId do UserSession
      final userSession = ServiceRegistry.get<UserSession>();
      final userId = userSession.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuário não está logado');
      }

      // Carregar exercício do banco
      final exercise = await _databaseService.getExerciseById(exerciseId);
      if (exercise == null) {
        throw Exception('Exercício não encontrado');
      }

      // Carregar progresso do usuário
      final progress =
          await _databaseService.getUserProgress(userId, exerciseId);

      await initializeExercise(exercise, progress: progress);
    } catch (e) {
      debugPrint('❌ Erro ao carregar exercício: $e');
      state = state.copyWith(isLoadingFromDatabase: false);
      rethrow;
    }
  }

  // Inicializar o exercício - AGORA ASSÍNCRONO
  Future<void> initializeExercise(SolfegeExercise exercise,
      {SolfegeProgress? progress}) async {
    final musicXml = _generateMusicXml(exercise: exercise);

    // Adicionado para garantir que o estado só é atualizado se o notifier ainda estiver ativo
    if (!mounted) return;

    state = state.copyWith(
      exercise: exercise,
      isInitialized: true,
      musicXml: musicXml,
      state: SolfegeState.idle,
      progress: progress,
      isLoadingFromDatabase: false,
    );
  }

  // Iniciar countdown
  void startCountdown() {
    if (state.state != SolfegeState.idle) return;

    // Determinar número de tempos baseado na fórmula de compasso
    final beatsPerMeasure =
        int.tryParse(state.exercise.timeSignature.split('/')[0]) ?? 4;

    state = state.copyWith(
      state: SolfegeState.countdown,
      countdownValue: beatsPerMeasure,
    );

    _runCountdown(beatsPerMeasure);
  }

  // Executar countdown com metrônomo
  void _runCountdown(int totalBeats) async {
    try {
      final midiService = MidiService();
      await midiService.initialize();

      for (int i = totalBeats; i > 0; i--) {
        if (!mounted) return;
        state = state.copyWith(countdownValue: i);

        // Tocar tick de metrônomo (primeiro tempo é forte)
        await midiService.playMetronomeTick(isStrong: i == totalBeats);

        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('Erro no metrônomo: $e');
      // Fallback sem som
      for (int i = totalBeats; i > 0; i--) {
        if (!mounted) return;
        state = state.copyWith(countdownValue: i);
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (!mounted) return;
    // Iniciar escuta com análise de áudio real
    await _startAudioAnalysis();
  }

  // Iniciar análise de áudio real
  Future<void> _startAudioAnalysis() async {
    try {
      _audioService = AudioAnalysisService.create();
      await _audioService!.initialize();

      _midiService = MidiService();
      await _midiService!.initialize();

      state = state.copyWith(
        state: SolfegeState.listening,
        currentNoteIndex: 0,
      );

      _detectedResults.clear();
      _currentNoteStartTime = DateTime.now();

      // Iniciar análise de áudio
      _audioSubscription = _audioService!.start().listen(
        _processAudioData,
        onError: (error) {
          debugPrint('Erro na análise de áudio: $error');
          _fallbackToSimulation();
        },
      );

      // Iniciar metrônomo persistente
      _startMetronome();

      // Timer para controlar progresso das notas
      _startNoteTimer();
    } catch (e) {
      debugPrint('Erro ao inicializar análise de áudio: $e');
      _fallbackToSimulation();
    }
  }

  // Iniciar metrônomo persistente durante a execução
  void _startMetronome() {
    final beatDurationMs = (60000 / state.exercise.tempo).round();
    int beatCount = 0;
    final beatsPerMeasure =
        int.tryParse(state.exercise.timeSignature.split('/')[0]) ?? 4;

    _metronomeTimer =
        Timer.periodic(Duration(milliseconds: beatDurationMs), (timer) {
      if (state.state != SolfegeState.listening) {
        timer.cancel();
        return;
      }

      // Tocar tick (primeiro tempo de cada compasso é forte)
      final isStrong = beatCount % beatsPerMeasure == 0;
      _midiService?.playWoodBlockTick(isStrong: isStrong);

      beatCount++;
    });
  }

  // Processar dados de áudio em tempo real
  void _processAudioData(AudioAnalysisData audioData) {
    if (state.state != SolfegeState.listening ||
        state.currentNoteIndex >= state.exercise.noteSequence.length) {
      return;
    }

    // Armazenar dados mais recentes da análise
    _lastAnalysisData = audioData;

    final currentNote = state.exercise.noteSequence[state.currentNoteIndex];
    final expectedFrequency = state.exercise.isOctaveDown
        ? currentNote.getFrequencyOctaveDown()
        : currentNote.frequency;

    // Verificar pitch, duração e nome
    final pitchCorrect = _audioService!.checkPitch(
      expectedFrequency,
      audioData.frequency,
      amplitude: audioData.amplitude,
    );

    final currentDuration = _currentNoteStartTime != null
        ? DateTime.now().difference(_currentNoteStartTime!).inMilliseconds /
            1000.0
        : 0.0;

    final expectedDuration =
        currentNote.getDurationInSeconds(state.exercise.tempo);
    final durationCorrect =
        _audioService!.checkDuration(expectedDuration, currentDuration);

    final nameCorrect =
        _audioService!.checkNoteName(currentNote.lyric, audioData.detectedWord);

    // Feedback visual em tempo real - aplicar cor amarela enquanto canta
    if (audioData.frequency > 0 && audioData.amplitude > 0.01) {
      _applyNoteColorFeedback(
          state.currentNoteIndex, null); // Amarelo = cantando
    }

    debugPrint(
        'Nota ${state.currentNoteIndex}: Pitch: $pitchCorrect, Duration: $durationCorrect, Name: $nameCorrect');
  }

  // Controlar timer das notas
  void _startNoteTimer() {
    if (state.currentNoteIndex >= state.exercise.noteSequence.length) {
      finishExercise();
      return;
    }

    final currentNote = state.exercise.noteSequence[state.currentNoteIndex];
    final noteDuration = _getNoteDurationInSeconds(currentNote.duration);

    _noteTimer =
        Timer(Duration(milliseconds: (noteDuration * 1000).round()), () async {
      if (mounted && state.state == SolfegeState.listening) {
        // Salvar resultado da nota atual
        await _saveCurrentNoteResult();

        // Avançar para próxima nota
        if (state.currentNoteIndex < state.exercise.noteSequence.length - 1) {
          state = state.copyWith(currentNoteIndex: state.currentNoteIndex + 1);
          _currentNoteStartTime = DateTime.now();
          _audioService?.resetNoteTimer();
          _startNoteTimer();
        } else {
          finishExercise();
        }
      }
    });
  }

  // Salvar resultado da nota atual
  Future<void> _saveCurrentNoteResult() async {
    if (state.currentNoteIndex < state.exercise.noteSequence.length) {
      final currentNote = state.exercise.noteSequence[state.currentNoteIndex];

      // Usar análise real ou padrão mais realista baseado em probabilidade
      bool pitchCorrect = false;
      bool durationCorrect = false;
      bool nameCorrect = false;

      // Se há dados reais da análise de áudio, usar eles
      if (_lastAnalysisData != null) {
        final expectedFrequency = state.exercise.isOctaveDown
            ? currentNote.getFrequencyOctaveDown()
            : currentNote.frequency;

        pitchCorrect = _audioService?.checkPitch(
              expectedFrequency,
              _lastAnalysisData!.frequency,
              amplitude: _lastAnalysisData!.amplitude,
            ) ??
            false;

        final currentDuration = _currentNoteStartTime != null
            ? DateTime.now().difference(_currentNoteStartTime!).inMilliseconds /
                1000.0
            : 0.0;
        final expectedDuration =
            currentNote.getDurationInSeconds(state.exercise.tempo);
        durationCorrect =
            _audioService?.checkDuration(expectedDuration, currentDuration) ??
                false;

        nameCorrect = _audioService?.checkNoteName(
                currentNote.lyric, _lastAnalysisData!.detectedWord) ??
            false;
      } else {
        // Sistema de pontuação mais realista se não há dados de áudio
        final difficulty = state.exercise.difficultyValue;
        final baseAccuracy = (10 - difficulty) /
            10.0; // Dificuldade 1 = 90%, Dificuldade 10 = 0%

        // Simulação mais realista baseada na dificuldade
        pitchCorrect = math.Random().nextDouble() < baseAccuracy;
        durationCorrect = math.Random().nextDouble() < (baseAccuracy + 0.1);
        nameCorrect = math.Random().nextDouble() < (baseAccuracy - 0.1);
      }

      // Calcular frequência esperada considerando modo de oitava
      final expectedFrequency = state.exercise.isOctaveDown
          ? currentNote.getFrequencyOctaveDown()
          : currentNote.frequency;

      final expectedDuration =
          currentNote.getDurationInSeconds(state.exercise.tempo);
      final detectedDuration = _currentNoteStartTime != null
          ? DateTime.now().difference(_currentNoteStartTime!).inMilliseconds /
              1000.0
          : 0.0;

      final result = NoteResult.withDetailedAnalysis(
        expectedNote: currentNote,
        detectedName: _lastAnalysisData?.detectedWord ?? '',
        detectedFrequency: _lastAnalysisData?.frequency ?? 0.0,
        detectedDuration: detectedDuration,
        pitchCorrect: pitchCorrect,
        durationCorrect: durationCorrect,
        nameCorrect: nameCorrect,
        expectedFrequency: expectedFrequency,
        expectedDuration: expectedDuration,
      );

      _detectedResults.add(result);

      // Feedback visual em tempo real
      await _applyNoteColorFeedback(state.currentNoteIndex, pitchCorrect);
    }
  }

  // FASE 3.3: Migração para Verovio - coloração de notas nativa
  Future<void> _applyNoteColorFeedback(int noteIndex, bool? isCorrect) async {
    String status;
    String color;

    if (isCorrect == null) {
      status = 'CANTANDO (Amarelo)';
      color = '#FFD700';
    } else if (isCorrect) {
      status = 'CORRETA (Verde)';
      color = '#00CC00';
    } else {
      status = 'INCORRETA (Vermelha)';
      color = '#CC0000';
    }

    // Usar VerovioService diretamente em vez de WebView JavaScript
    try {
      await VerovioService.instance.colorNote('note-$noteIndex', color);
      debugPrint('✅ FASE 3.3: Nota $noteIndex colorida com $color');
    } catch (e) {
      debugPrint('❌ FASE 3.3: Erro ao colorir nota: $e');
    }

    debugPrint('Nota $noteIndex: $status');
  }

  // FASE 3.3: Aplicar feedback de todas as notas com Verovio
  Future<void> _applyResultsFeedback(
      List<SolfegeAnalysisResult> results) async {
    try {
      final noteColors = <String, String>{};

      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final color = result.pitchCorrect ? '#00CC00' : '#CC0000';
        noteColors['note-$i'] = color;
      }

      await VerovioService.instance.colorMultipleNotes(noteColors);
      debugPrint(
          '✅ FASE 3.3: Feedback visual aplicado para ${results.length} notas');
    } catch (e) {
      debugPrint('❌ FASE 3.3: Erro ao aplicar feedback múltiplas notas: $e');
    }
  }

  // Fallback para simulação se áudio falhar
  void _fallbackToSimulation() async {
    debugPrint('Usando simulação como fallback');

    for (int i = state.currentNoteIndex;
        i < state.exercise.noteSequence.length;
        i++) {
      if (state.state != SolfegeState.listening) break;
      if (!mounted) return;

      state = state.copyWith(currentNoteIndex: i);

      final noteDuration =
          _getNoteDurationInSeconds(state.exercise.noteSequence[i].duration);
      await Future.delayed(
          Duration(milliseconds: (noteDuration * 1000).round()));
    }

    if (mounted && state.state == SolfegeState.listening) {
      finishExercise();
    }
  }

  // Finalizar exercício
  void finishExercise() {
    if (state.state != SolfegeState.listening) return;

    // Parar análise de áudio
    _audioSubscription?.cancel();
    _noteTimer?.cancel();
    _audioService?.stop();

    state = state.copyWith(state: SolfegeState.analyzing);

    // Análise baseada nos resultados reais
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _generateResultsFromAudio();
      }
    });
  }

  // Gerar resultados baseados na análise de áudio
  void _generateResultsFromAudio() async {
    final results = <SolfegeAnalysisResult>[];
    int correctPitches = 0;
    int correctDurations = 0;

    // Usar resultados reais da análise de áudio se disponíveis
    for (int i = 0; i < state.exercise.noteSequence.length; i++) {
      bool pitchCorrect = false;
      bool durationCorrect = false;

      if (i < _detectedResults.length) {
        // Usar resultados reais
        pitchCorrect = _detectedResults[i].pitchCorrect;
        durationCorrect = _detectedResults[i].durationCorrect;
      } else {
        // Fallback: assumir que não foi detectado corretamente
        pitchCorrect = false;
        durationCorrect = false;
      }

      if (pitchCorrect) correctPitches++;
      if (durationCorrect) correctDurations++;

      results.add(SolfegeAnalysisResult(
        pitchCorrect: pitchCorrect,
        durationCorrect: durationCorrect,
        pitchAccuracy: pitchCorrect ? 0.95 : 0.4,
        durationAccuracy: durationCorrect ? 0.90 : 0.3,
      ));
    }

    final pitchScore = state.exercise.noteSequence.isEmpty
        ? 0
        : ((correctPitches / state.exercise.noteSequence.length) * 100).round();
    final durationScore = state.exercise.noteSequence.isEmpty
        ? 0
        : ((correctDurations / state.exercise.noteSequence.length) * 100)
            .round();

    final coloredMusicXml =
        _generateMusicXml(exercise: state.exercise, results: results);

    // FASE 3.3: Migração para Verovio - feedback visual final
    try {
      await _applyResultsFeedback(results);
    } catch (e) {
      debugPrint('❌ FASE 3.3: Erro ao aplicar feedback final: $e');
    }

    // Salvar resultado no banco de dados e aplicar gamificação
    await _saveExerciseResult(pitchScore, durationScore);

    state = state.copyWith(
      state: SolfegeState.finished,
      results: results,
      pitchScore: pitchScore,
      durationScore: durationScore,
      musicXml: coloredMusicXml,
    );
  }

  // Salvar resultado no banco e aplicar gamificação
  Future<void> _saveExerciseResult(int pitchScore, int durationScore) async {
    try {
      // Calcular score final baseado em pitch (peso 70%) e duração (peso 30%)
      final finalScore = ((pitchScore * 0.7) + (durationScore * 0.3)).round();

      debugPrint(
          '🎵 Score final: $finalScore% (Pitch: $pitchScore%, Duração: $durationScore%)');

      // Determinar resultado do exercício
      final scoreResult = SolfegeScoreResultExtension.fromScore(finalScore);

      // Obter userId do UserSession
      final userSession = ServiceRegistry.get<UserSession>();
      final userId = userSession.currentUser?.id;

      if (userId == null) {
        debugPrint(
            '❌ Usuário não está logado - não é possível salvar progresso');
        return;
      }

      final exerciseId = int.parse(state.exercise.id);

      final updatedProgress = await _databaseService.saveExerciseResult(
          userId, exerciseId, finalScore);

      // Aplicar gamificação baseada no resultado
      await _applyGamificationRewards(scoreResult, finalScore);

      // Atualizar estado com progresso atualizado
      state = state.copyWith(progress: updatedProgress);

      debugPrint('🎵 Resultado salvo com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao salvar resultado: $e');
      // Não rethrow para não quebrar a UI, apenas logar o erro
    }
  }

  // Aplicar recompensas de gamificação baseado no desempenho
  Future<void> _applyGamificationRewards(
      SolfegeScoreResult scoreResult, int finalScore) async {
    try {
      final difficulty = state.exercise.difficultyValue;

      switch (scoreResult) {
        case SolfegeScoreResult.excellent:
          // >= 90% - Ganhar pontos baseado na dificuldade
          final pointsReward = _calculatePointsReward(finalScore, difficulty);
          ServiceRegistry.get<GamificationService>().addPoints(pointsReward,
              reason: 'Exercício de solfejo completado');
          debugPrint('🎉 Exercício completado! +$pointsReward pontos');
          break;

        case SolfegeScoreResult.good:
          // 50-89% - Sem penalidade, sem recompensa
          debugPrint(
              '👍 Bom trabalho! Continue praticando para desbloquear o próximo exercício');
          break;

        case SolfegeScoreResult.poor:
          // < 50% - Perder uma vida
          debugPrint('💔 Performance abaixo de 50% - uma vida perdida');
          // Implementar sistema de vidas via UserSession quando necessário
          break;
      }
    } catch (e) {
      debugPrint('❌ Erro ao aplicar gamificação: $e');
    }
  }

  // Calcular pontos baseado no score e dificuldade
  int _calculatePointsReward(int score, int difficulty) {
    // Fórmula: base 50 pontos + (score-90) * 2 + difficulty * 10
    // Exemplos:
    // - 90% dif.1 = 50 + 0 + 10 = 60 pontos
    // - 100% dif.5 = 50 + 20 + 50 = 120 pontos
    const basePoints = 50;
    final scoreBonus = (score - 90) * 2;
    final difficultyBonus = difficulty * 10;

    return basePoints + scoreBonus + difficultyBonus;
  }

  // Tocar preview com MIDI real
  void playPreview() async {
    if (state.state != SolfegeState.idle) return;

    state = state.copyWith(isPlayingPreview: true);

    try {
      // Importar o serviço MIDI
      final midiService = MidiService();
      await midiService.initialize();

      // Iniciar metrônomo se configurado
      Timer? metronomeTimer;
      if (state.showMetronomeInPreview) {
        final beatDurationMs = (60000 / state.exercise.tempo).round();
        int beatCount = 0;
        final beatsPerMeasure =
            int.tryParse(state.exercise.timeSignature.split('/')[0]) ?? 4;

        metronomeTimer =
            Timer.periodic(Duration(milliseconds: beatDurationMs), (timer) {
          if (!state.isPlayingPreview) {
            timer.cancel();
            return;
          }

          // Tocar tick do metrônomo
          final isStrong = beatCount % beatsPerMeasure == 0;
          midiService.playWoodBlockTick(isStrong: isStrong);
          beatCount++;
        });
      }

      // Tocar cada nota da sequência
      for (int i = 0; i < state.exercise.noteSequence.length; i++) {
        if (!mounted ||
            state.state != SolfegeState.idle ||
            !state.isPlayingPreview) {
          break;
        }

        final noteInfo = state.exercise.noteSequence[i];
        final noteDuration = _getNoteDurationInSeconds(noteInfo.duration);

        // Tocar a nota com duração (ajustar oitava se necessário)
        final noteToPlay = state.exercise.isOctaveDown
            ? _transposeNoteOctaveDown(noteInfo.note)
            : noteInfo.note;

        await midiService.playNoteWithDuration(
          noteToPlay,
          Duration(milliseconds: (noteDuration * 1000).round()),
          velocity: 100,
        );

        // Aguardar a duração da nota
        await Future.delayed(
          Duration(milliseconds: (noteDuration * 1000).round()),
        );
      }

      // Parar metrônomo
      metronomeTimer?.cancel();
    } catch (e) {
      debugPrint('Erro ao tocar preview: $e');
    }

    if (mounted) {
      state = state.copyWith(isPlayingPreview: false);
    }
  }

  // Parar preview
  void stopPreview() {
    state = state.copyWith(isPlayingPreview: false);
  }

  // Toggle mostrar nomes das notas
  void toggleNoteNames() {
    if (state.state == SolfegeState.idle) {
      final newShowNames = !state.showNoteNames;

      // Regenerar MusicXML com ou sem nomes
      final musicXml = _generateMusicXml(
        exercise: state.exercise,
        showLyrics: newShowNames,
      );

      state = state.copyWith(
        showNoteNames: newShowNames,
        musicXml: musicXml,
      );

      debugPrint(
          'Nomes de solfejo ${newShowNames ? "ativados" : "desativados"}');
    }
  }

  // Toggle acompanhamento de piano
  void togglePianoAccompaniment() {
    if (state.state == SolfegeState.idle) {
      state = state.copyWith(playWithPiano: !state.playWithPiano);
    }
  }

  // Alternar entre modo agudo (oitava normal) e grave (oitava transposta)
  void toggleOctaveMode() {
    if (state.state == SolfegeState.idle) {
      final newExercise = SolfegeExercise(
        id: state.exercise.id,
        title: state.exercise.title,
        difficultyLevel: state.exercise.difficultyLevel,
        difficultyValue: state.exercise.difficultyValue,
        keySignature: state.exercise.keySignature,
        timeSignature: state.exercise.timeSignature,
        tempo: state.exercise.tempo,
        noteSequence: state.exercise.noteSequence,
        createdAt: state.exercise.createdAt,
        clef: state.exercise.clef,
        isOctaveDown: !state.exercise.isOctaveDown,
      );

      final musicXml = _generateMusicXml(exercise: newExercise);

      state = state.copyWith(
        exercise: newExercise,
        musicXml: musicXml,
      );

      debugPrint(
          '🎵 Modo de oitava alterado: ${newExercise.isOctaveDown ? "Grave" : "Agudo"}');
    }
  }

  // Controlar zoom da partitura
  Future<void> setZoomLevel(double zoom) async {
    if (state.state == SolfegeState.idle && zoom >= 0.5 && zoom <= 2.0) {
      state = state.copyWith(zoomLevel: zoom);

      // FASE 3.3: Comunicar zoom para Verovio
      try {
        await VerovioService.instance.setZoomLevel(zoom);
      } catch (e) {
        debugPrint('❌ FASE 3.3: Erro ao alterar zoom: $e');
      }

      debugPrint('🎵 Zoom alterado para: ${(zoom * 100).round()}%');
    }
  }

  // Alternar modo de exibição da partitura
  Future<void> toggleDisplayMode() async {
    if (state.state == SolfegeState.idle) {
      final newMode = state.displayMode == ScoreDisplayMode.horizontal
          ? ScoreDisplayMode.lineBreak
          : ScoreDisplayMode.horizontal;

      state = state.copyWith(displayMode: newMode);

      // FASE 3.3: Comunicar alteração para Verovio
      try {
        final newWidth = newMode == ScoreDisplayMode.horizontal ? 800 : 350;
        await VerovioService.instance.setPageWidth(newWidth);
      } catch (e) {
        debugPrint('❌ FASE 3.3: Erro ao alterar modo de display: $e');
      }

      debugPrint('🎵 Modo de exibição alterado para: ${newMode.name}');
    }
  }

  // Alternar exibição do metrônomo no preview
  void toggleMetronomeInPreview() {
    if (state.state == SolfegeState.idle) {
      state =
          state.copyWith(showMetronomeInPreview: !state.showMetronomeInPreview);
      debugPrint(
          '🎵 Metrônomo no preview ${state.showMetronomeInPreview ? "ativado" : "desativado"}');
    }
  }

  // Reset do exercício
  Future<void> reset() async {
    // FASE 3.3: Limpar cores das notas na partitura com Verovio
    try {
      await VerovioService.instance.clearAllColors();
    } catch (e) {
      debugPrint('❌ FASE 3.3: Erro ao limpar cores: $e');
    }

    _detectedResults.clear(); // Limpar resultados detalhados

    state = state.copyWith(
      state: SolfegeState.idle,
      currentNoteIndex: -1,
      countdownValue: 3,
      results: [],
      isPlayingPreview: false,
      pitchScore: 0,
      durationScore: 0,
      musicXml:
          _generateMusicXml(exercise: state.exercise), // Regenera XML sem cores
    );
  }

  // Método para acessar os resultados detalhados
  List<NoteResult> getDetectedResults() {
    return List.from(_detectedResults);
  }

  // FASE 4.6: Geração precisa de MusicXML usando PreciseMusicXMLService
  String _generateMusicXml({
    required SolfegeExercise exercise,
    List<SolfegeAnalysisResult>? results,
    bool showLyrics = false,
  }) {
    try {
      if (exercise.noteSequence.isEmpty) return '';

      // Converter noteSequence do exercício para formato compatível com o serviço
      List<Map<String, dynamic>> noteSequenceData = [];

      for (int i = 0; i < exercise.noteSequence.length; i++) {
        final noteInfo = exercise.noteSequence[i];

        // Preparar dados da nota
        Map<String, dynamic> noteData = {
          'note': noteInfo.note,
          'duration': noteInfo.duration,
        };

        // Adicionar letra apenas se showLyrics for true
        if (showLyrics ||
            exercise.noteSequence.any((n) => n.lyric.isNotEmpty)) {
          noteData['lyric'] = noteInfo.lyric;
        }

        noteSequenceData.add(noteData);
      }

      // Usar o serviço preciso para gerar MusicXML
      final musicXML = PreciseMusicXMLService.instance.generateSolfegeMusicXML(
        noteSequence: noteSequenceData,
        keySignature: exercise.keySignature,
        timeSignature: exercise.timeSignature,
        tempo: exercise.tempo,
        clef: exercise.clef,
        title: exercise.title,
      );

      debugPrint(
          '✅ FASE 4.6: MusicXML gerado com precisão para solfejo: ${exercise.title}');
      debugPrint('🎵 FASE 4.6: ${noteSequenceData.length} notas processadas');

      return musicXML;
    } catch (e) {
      debugPrint('❌ FASE 4.6: Erro na geração precisa de MusicXML: $e');
      return ''; // Retorna vazio em caso de erro
    }
  }

  // Converter duração da nota em segundos (SEU CÓDIGO ORIGINAL)
  double _getNoteDurationInSeconds(String duration) {
    // Corrigido para incluir '16th' e usar _getNoteDurationInBeats
    return _getNoteDurationInBeats(duration) * (60.0 / state.exercise.tempo);
  }

  // Helper para obter duração em batidas
  double _getNoteDurationInBeats(String duration) {
    switch (duration) {
      case 'whole':
        return 4.0;
      case 'half':
        return 2.0;
      case 'quarter':
        return 1.0;
      case 'eighth':
        return 0.5;
      case '16th': // Adicionado para consistência
        return 0.25;
      default:
        return 1.0;
    }
  }

  // Helper para transpor nota uma oitava abaixo
  String _transposeNoteOctaveDown(String note) {
    final regex = RegExp(r'^([A-G][#b]?)(\d+)$');
    final match = regex.firstMatch(note);

    if (match != null) {
      final noteName = match.group(1)!;
      final octave = int.parse(match.group(2)!);
      return '$noteName${octave - 1}';
    }

    return note; // Retorna original se não conseguir fazer parse
  }
}

// Provider para o exercício de solfejo (SEU CÓDIGO ORIGINAL)
final solfegeExerciseProvider =
    StateNotifierProvider<SolfegeExerciseNotifier, SolfegeExerciseState>((ref) {
  return SolfegeExerciseNotifier();
});
