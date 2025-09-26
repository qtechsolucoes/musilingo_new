// lib/features/practice_solfege/providers/solfege_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/services/audio_analysis_service.dart';
import 'package:musilingo/app/services/unified_midi_service.dart';
import 'package:musilingo/app/core/service_registry.dart';

enum SolfegeState {
  idle,
  countdown,
  listening,
  analyzing,
  finished,
}

class SolfegeControllerState {
  final SolfegeState state;
  final int countdownValue;
  final int currentNoteIndex;
  final List<NoteResult> results;
  final bool isInitialized;
  final bool playWithPiano;
  final bool isPlayingPreview;
  final bool showNoteNames;
  final List<bool> noteNamesRevealed;
  final bool isMetronomeActive;

  const SolfegeControllerState({
    this.state = SolfegeState.idle,
    this.countdownValue = 0,
    this.currentNoteIndex = -1,
    this.results = const [],
    this.isInitialized = false,
    this.playWithPiano = false,
    this.isPlayingPreview = false,
    this.showNoteNames = true,
    this.noteNamesRevealed = const [],
    this.isMetronomeActive = false,
  });

  SolfegeControllerState copyWith({
    SolfegeState? state,
    int? countdownValue,
    int? currentNoteIndex,
    List<NoteResult>? results,
    bool? isInitialized,
    bool? playWithPiano,
    bool? isPlayingPreview,
    bool? showNoteNames,
    List<bool>? noteNamesRevealed,
    bool? isMetronomeActive,
  }) {
    return SolfegeControllerState(
      state: state ?? this.state,
      countdownValue: countdownValue ?? this.countdownValue,
      currentNoteIndex: currentNoteIndex ?? this.currentNoteIndex,
      results: results ?? this.results,
      isInitialized: isInitialized ?? this.isInitialized,
      playWithPiano: playWithPiano ?? this.playWithPiano,
      isPlayingPreview: isPlayingPreview ?? this.isPlayingPreview,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      noteNamesRevealed: noteNamesRevealed ?? this.noteNamesRevealed,
      isMetronomeActive: isMetronomeActive ?? this.isMetronomeActive,
    );
  }
}

class SolfegeController extends StateNotifier<SolfegeControllerState> {
  final SolfegeExercise exercise;

  // Serviços obtidos via ServiceRegistry
  final AudioAnalysisService _audioAnalysisService =
      ServiceRegistry.get<AudioAnalysisService>();
  final UnifiedMidiService _midiService =
      ServiceRegistry.get<UnifiedMidiService>();

  // Timers e Subscriptions
  Timer? _noteTimer;
  Timer? _metronomeTimer;
  StreamSubscription<AudioAnalysisData>? _audioSubscription;

  // Controle de concorrência
  bool _isSchedulingNote = false;
  bool _isEvaluatingNote = false;

  // Controle do Metrônomo

  // Buffers para análise
  final List<double> _pitchBuffer = [];
  final List<double> _amplitudeBuffer = [];
  final List<String> _wordBuffer = [];
  double _lastDetectedDuration = 0.0;

  SolfegeController({required this.exercise})
      : super(const SolfegeControllerState()) {
    _initializeController();
  }

  void _initializeController() {
    // Inicializar o array de visibilidade dos nomes das notas
    final noteNamesRevealed = List.filled(exercise.noteSequence.length, false);
    state = state.copyWith(noteNamesRevealed: noteNamesRevealed);
    _initializeServices();
  }

  // Getters - FOCO APENAS EM PITCH E DURAÇÃO
  int get score {
    if (state.results.isEmpty) return 0;
    final correctCount =
        state.results.where((r) => r.pitchCorrect && r.durationCorrect).length;
    return ((correctCount / state.results.length) * 100).round();
  }

  // Scores individuais para feedback detalhado
  int get pitchScore {
    if (state.results.isEmpty) return 0;
    final correctCount = state.results.where((r) => r.pitchCorrect).length;
    return ((correctCount / state.results.length) * 100).round();
  }

  int get durationScore {
    if (state.results.isEmpty) return 0;
    final correctCount = state.results.where((r) => r.durationCorrect).length;
    return ((correctCount / state.results.length) * 100).round();
  }

  // Score apenas de pitch (para casos onde duração é menos importante)
  int get pitchOnlyScore {
    if (state.results.isEmpty) return 0;
    final correctCount = state.results.where((r) => r.pitchCorrect).length;
    return ((correctCount / state.results.length) * 100).round();
  }

  Future<void> _initializeServices() async {
    try {
      // Verifica se os serviços necessários estão inicializados
      if (!_audioAnalysisService.isInitialized) {
        debugPrint('❌ AudioAnalysisService não inicializado!');
        return;
      }

      if (!_midiService.isInitialized) {
        debugPrint('❌ UnifiedMidiService não inicializado!');
        return;
      }

      state = state.copyWith(isInitialized: true);
      debugPrint('✅ SolfegeController inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar SolfegeController: $e');
    }
  }

  // Método para iniciar exercício
  Future<void> startExercise() async {
    if (!state.isInitialized) {
      debugPrint('❌ Controller não inicializado');
      return;
    }

    try {
      state = state.copyWith(
        state: SolfegeState.countdown,
        currentNoteIndex: -1,
        results: [],
      );

      // Countdown de 3 segundos
      for (int i = 3; i > 0; i--) {
        state = state.copyWith(countdownValue: i);
        await Future.delayed(const Duration(seconds: 1));
      }

      // Preparar o áudio analysis
      await _setupAudioAnalysis();

      // Iniciar primeira nota
      await _scheduleNextNote();
    } catch (e) {
      debugPrint('❌ Erro ao iniciar exercício: $e');
      _finishExercise();
    }
  }

  Future<void> _setupAudioAnalysis() async {
    try {
      // Cancelar subscription anterior se existir
      await _audioSubscription?.cancel();

      // Iniciar análise de áudio
      await _audioAnalysisService.startAnalysis();

      // Configurar subscription para receber dados de análise
      _audioSubscription = _audioAnalysisService.audioDataStream.listen(
        _processAudioData,
        onError: (error) {
          debugPrint('❌ Erro no stream de áudio: $error');
        },
      );

      debugPrint('✅ Análise de áudio configurada');
    } catch (e) {
      debugPrint('❌ Erro ao configurar análise de áudio: $e');
    }
  }

  void _processAudioData(AudioAnalysisData data) {
    if (_isEvaluatingNote || state.state != SolfegeState.listening) {
      return;
    }

    // Adicionar dados aos buffers
    _pitchBuffer.add(data.pitch);
    _amplitudeBuffer.add(data.amplitude);
    if (data.detectedWord.isNotEmpty) {
      _wordBuffer.add(data.detectedWord);
    }

    // Detectar duração baseada na amplitude
    if (data.amplitude > 0.1) {
      _lastDetectedDuration += 0.1; // Aproximadamente 100ms por análise
    }
  }

  Future<void> _scheduleNextNote() async {
    if (_isSchedulingNote) return;
    _isSchedulingNote = true;

    try {
      final nextIndex = state.currentNoteIndex + 1;

      if (nextIndex >= exercise.noteSequence.length) {
        _finishExercise();
        return;
      }

      final note = exercise.noteSequence[nextIndex];
      state = state.copyWith(
        currentNoteIndex: nextIndex,
        state: SolfegeState.listening,
      );

      debugPrint('🎵 Nota atual: ${note.note} (${note.lyric})');

      // Limpar buffers para nova nota
      _clearBuffers();

      // Tocar a nota se piano estiver ativado
      if (state.playWithPiano) {
        await _midiService.playNote(note.note);
      }

      // Configurar timer para duração da nota
      final noteDurationMs = _getNoteDurationInMs(note.duration);
      _noteTimer?.cancel();
      _noteTimer = Timer(Duration(milliseconds: noteDurationMs), () {
        _evaluateCurrentNote();
      });
    } catch (e) {
      debugPrint('❌ Erro ao agendar próxima nota: $e');
    } finally {
      _isSchedulingNote = false;
    }
  }

  void _clearBuffers() {
    _pitchBuffer.clear();
    _amplitudeBuffer.clear();
    _wordBuffer.clear();
    _lastDetectedDuration = 0.0;
  }

  int _getNoteDurationInMs(String duration) {
    // Conversão básica de duração musical para millisegundos
    switch (duration.toLowerCase()) {
      case 'whole':
        return 4000;
      case 'half':
        return 2000;
      case 'quarter':
        return 1000;
      case 'eighth':
        return 500;
      case 'sixteenth':
        return 250;
      default:
        return 1000;
    }
  }

  Future<void> _evaluateCurrentNote() async {
    if (_isEvaluatingNote) return;
    _isEvaluatingNote = true;

    try {
      state = state.copyWith(state: SolfegeState.analyzing);

      final currentNote = exercise.noteSequence[state.currentNoteIndex];
      final result = await _analyzePerformance(currentNote);

      // Atualizar resultados
      final newResults = List<NoteResult>.from(state.results)..add(result);
      state = state.copyWith(results: newResults);

      debugPrint(
          '📊 Resultado: Pitch=${result.pitchCorrect}, Duration=${result.durationCorrect}');

      // Pequena pausa antes da próxima nota
      await Future.delayed(const Duration(milliseconds: 500));

      // Próxima nota
      await _scheduleNextNote();
    } catch (e) {
      debugPrint('❌ Erro ao avaliar nota: $e');
    } finally {
      _isEvaluatingNote = false;
    }
  }

  Future<NoteResult> _analyzePerformance(NoteInfo expectedNote) async {
    // Análise de pitch
    final pitchCorrect = _analyzePitch(expectedNote);

    // Análise de duração
    final durationCorrect = _analyzeDuration(expectedNote);

    return NoteResult(
      expectedNote: expectedNote,
      detectedName: _wordBuffer.isNotEmpty ? _wordBuffer.last : '',
      detectedFrequency: _pitchBuffer.isNotEmpty ? _pitchBuffer.last : 0.0,
      detectedDuration: _lastDetectedDuration,
      pitchCorrect: pitchCorrect,
      durationCorrect: durationCorrect,
      nameCorrect: _wordBuffer.isNotEmpty
          ? _wordBuffer.last.toLowerCase() == expectedNote.lyric.toLowerCase()
          : false,
    );
  }

  bool _analyzePitch(NoteInfo expectedNote) {
    if (_pitchBuffer.isEmpty) return false;

    final averagePitch =
        _pitchBuffer.reduce((a, b) => a + b) / _pitchBuffer.length;
    final expectedFrequency = expectedNote.frequency;

    // Tolerância de ±50 cents (aproximadamente ±3% da frequência)
    const tolerance = 0.03;
    final lowerBound = expectedFrequency * (1 - tolerance);
    final upperBound = expectedFrequency * (1 + tolerance);

    return averagePitch >= lowerBound && averagePitch <= upperBound;
  }

  bool _analyzeDuration(NoteInfo expectedNote) {
    final expectedDurationMs = _getNoteDurationInMs(expectedNote.duration);
    final detectedDurationMs = (_lastDetectedDuration * 1000).round();

    // Tolerância de ±30% da duração esperada
    const tolerance = 0.3;
    final lowerBound = expectedDurationMs * (1 - tolerance);
    final upperBound = expectedDurationMs * (1 + tolerance);

    return detectedDurationMs >= lowerBound && detectedDurationMs <= upperBound;
  }

  void _finishExercise() {
    state = state.copyWith(state: SolfegeState.finished);
    _cleanup();
    debugPrint('🏁 Exercício finalizado. Score: $score%');
  }

  // Métodos de controle público
  void togglePiano() {
    state = state.copyWith(playWithPiano: !state.playWithPiano);
  }

  void toggleNoteNames() {
    state = state.copyWith(showNoteNames: !state.showNoteNames);
  }

  void revealNoteName(int index) {
    if (index < 0 || index >= state.noteNamesRevealed.length) return;

    final newRevealed = List<bool>.from(state.noteNamesRevealed);
    newRevealed[index] = true;
    state = state.copyWith(noteNamesRevealed: newRevealed);
  }

  Future<void> playPreview() async {
    if (state.isPlayingPreview || !state.isInitialized) return;

    state = state.copyWith(isPlayingPreview: true);

    try {
      for (final note in exercise.noteSequence) {
        await _midiService.playNote(note.note);
        await Future.delayed(const Duration(milliseconds: 800));
        await _midiService.stopNote(note.note);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('❌ Erro ao reproduzir preview: $e');
    } finally {
      state = state.copyWith(isPlayingPreview: false);
    }
  }

  void _cleanup() {
    _noteTimer?.cancel();
    _metronomeTimer?.cancel();
    _audioSubscription?.cancel();
    _audioAnalysisService.stopAnalysis();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

// Provider principal
final solfegeControllerProvider = StateNotifierProvider.family<
    SolfegeController, SolfegeControllerState, SolfegeExercise>(
  (ref, exercise) => SolfegeController(exercise: exercise),
);

// Providers derivados para acesso direto aos getters
final solfegeScoreProvider =
    Provider.family<int, SolfegeExercise>((ref, exercise) {
  final controller = ref.watch(solfegeControllerProvider(exercise).notifier);
  return controller.score;
});

final solfegePitchScoreProvider =
    Provider.family<int, SolfegeExercise>((ref, exercise) {
  final controller = ref.watch(solfegeControllerProvider(exercise).notifier);
  return controller.pitchScore;
});

final solfegeDurationScoreProvider =
    Provider.family<int, SolfegeExercise>((ref, exercise) {
  final controller = ref.watch(solfegeControllerProvider(exercise).notifier);
  return controller.durationScore;
});
