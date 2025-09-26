// lib/app/services/unified_midi_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/core/service_registry.dart';

/// Utilitário consolidado para conversão de notas musicais
class MidiUtils {
  static final Map<String, int> _noteCache = {};
  static const int _maxCacheSize = 100;

  static const Map<String, int> _baseNotes = {
    'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11
  };

  /// Converte nome da nota para número MIDI com cache otimizado
  static int noteNameToMidi(String noteName) {
    if (_noteCache.containsKey(noteName)) {
      return _noteCache[noteName]!;
    }

    final result = _calculateMidiNote(noteName);

    // Limpar cache se muito grande
    if (_noteCache.length >= _maxCacheSize) {
      _noteCache.clear();
      debugPrint('MIDI cache limpo - tamanho otimizado');
    }

    _noteCache[noteName] = result;
    return result;
  }

  static int _calculateMidiNote(String noteName) {
    // Handle REST e casos especiais
    if (noteName.toUpperCase().contains("REST") || noteName.isEmpty) return 0;

    // Pattern para notas: C4, F#5, Bb3, etc.
    final noteRegex = RegExp(r'^([A-G])([#b]?)(\d+)$');
    final match = noteRegex.firstMatch(noteName.toUpperCase());

    if (match == null) {
      debugPrint('WARN: Nota inválida "$noteName", usando C4 (60)');
      return 60; // C4 default
    }

    final noteLetter = match.group(1)!;
    final accidental = match.group(2) ?? '';
    final octave = int.tryParse(match.group(3)!) ?? 4;

    // Calcular MIDI note: C4 = 60
    int midiNote = _baseNotes[noteLetter]! + (octave + 1) * 12;

    // Aplicar acidentes
    switch (accidental) {
      case '#': midiNote += 1; break;
      case 'b': midiNote -= 1; break;
    }

    // Clamp para range MIDI válido
    return midiNote.clamp(0, 127);
  }

  /// Converte duração de string para milissegundos baseado no tempo
  static int getDurationMs(String duration, int tempo) {
    final beatMs = 60000 ~/ tempo;

    const durationMultipliers = {
      'whole': 4.0,    'w': 4.0,
      'half': 2.0,     'h': 2.0,
      'quarter': 1.0,  'q': 1.0,
      'eighth': 0.5,   'e': 0.5,
      'sixteenth': 0.25, 's': 0.25,
      '16th': 0.25,
    };

    final multiplier = durationMultipliers[duration.toLowerCase()] ?? 1.0;
    return (beatMs * multiplier).round();
  }

  /// Limpa cache - útil para testes e limpeza de memória
  static void clearCache() {
    _noteCache.clear();
  }
}

/// Configurações de instrumentos MIDI
class MidiInstruments {
  // Melodic instruments (Bank 0)
  static const int acousticGrandPiano = 0;
  static const int electricPiano = 4;
  static const int violin = 40;

  // Percussion (Bank 128, Channel 9)
  static const int acousticBassDrum = 35;
  static const int acousticSnare = 38;
  static const int closedHiHat = 42;
  static const int woodBlockHigh = 77;
  static const int woodBlockLow = 76;
  static const int claves = 75;
}

/// Serviço MIDI unificado e otimizado
class UnifiedMidiService implements Disposable {
  // CORREÇÃO: Removido padrão Singleton

  final MidiPro _midiPro = MidiPro();
  bool _isInitialized = false;
  int? _melodicSoundfontId;
  int? _percussionSoundfontId;

  // Controle de notas ativas para cleanup
  final Set<int> _activeNotes = {};
  final Map<int, Timer> _noteTimers = {};

  /// Inicializa o serviço MIDI com tratamento robusto de erros
  Future<DatabaseResult<void>> initialize() async {
    if (_isInitialized) return const Success(null);

    try {
      // Carrega soundfont para instrumentos melódicos
      _melodicSoundfontId = await _midiPro.loadSoundfont(
        path: 'assets/sf2/GeneralUserGS.sf2',
        bank: 0,
        program: MidiInstruments.acousticGrandPiano,
      );

      // Carrega soundfont para percussão
      _percussionSoundfontId = await _midiPro.loadSoundfont(
        path: 'assets/sf2/GeneralUserGS.sf2',
        bank: 128,
        program: 0,
      );

      _isInitialized = true;
      debugPrint('✅ UnifiedMidiService inicializado com sucesso');
      return const Success(null);
    } catch (e) {
      debugPrint('❌ Erro ao inicializar UnifiedMidiService: $e');
      return Failure(
        'Falha ao inicializar sistema de áudio MIDI',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Toca uma nota musical
  Future<DatabaseResult<void>> playNote(
    String noteName, {
    int velocity = 127,
    int? customInstrument,
  }) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isFailure) return initResult;
    }

    try {
      final midiNote = MidiUtils.noteNameToMidi(noteName);
      if (midiNote == 0) return const Success(null); // Skip rests

      await _midiPro.playNote(
        sfId: _melodicSoundfontId!,
        channel: 0,
        key: midiNote,
        velocity: velocity.clamp(0, 127),
      );

      _activeNotes.add(midiNote);
      return const Success(null);
    } catch (e) {
      return Failure(
        'Erro ao tocar nota $noteName',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Para uma nota específica
  Future<DatabaseResult<void>> stopNote(String noteName) async {
    if (!_isInitialized) return const Success(null);

    try {
      final midiNote = MidiUtils.noteNameToMidi(noteName);
      if (midiNote == 0) return const Success(null);

      await _midiPro.stopNote(
        sfId: _melodicSoundfontId!,
        channel: 0,
        key: midiNote,
      );

      _activeNotes.remove(midiNote);
      _noteTimers[midiNote]?.cancel();
      _noteTimers.remove(midiNote);

      return const Success(null);
    } catch (e) {
      return Failure(
        'Erro ao parar nota $noteName',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Toca nota com duração específica
  Future<DatabaseResult<void>> playNoteWithDuration(
    String noteName,
    Duration duration, {
    int velocity = 127,
  }) async {
    final playResult = await playNote(noteName, velocity: velocity);
    if (playResult.isFailure) return playResult;

    final midiNote = MidiUtils.noteNameToMidi(noteName);
    if (midiNote == 0) return const Success(null);

    // Cancelar timer anterior se existir
    _noteTimers[midiNote]?.cancel();

    // Agendar parada da nota
    _noteTimers[midiNote] = Timer(duration, () {
      stopNote(noteName);
    });

    return const Success(null);
  }

  /// Toca sequência de notas com callbacks de progresso
  Future<DatabaseResult<void>> playNoteSequence({
    required List<Map<String, dynamic>> notes,
    required int tempo,
    Function(int noteIndex)? onNotePlayed,
    VoidCallback? onPlaybackComplete,
    bool allowInterruption = true,
  }) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isFailure) return initResult;
    }

    try {
      for (int i = 0; i < notes.length; i++) {
        final noteData = notes[i];
        final pitch = noteData['pitch'] as String? ?? noteData['note'] as String?;
        final duration = noteData['duration'] as String?;

        if (pitch == null || duration == null) continue;

        // Notificar progresso
        onNotePlayed?.call(i);

        final durationMs = MidiUtils.getDurationMs(duration, tempo);

        if (pitch.toUpperCase() != "REST") {
          await playNoteWithDuration(
            pitch,
            Duration(milliseconds: durationMs),
          );
        }

        await Future.delayed(Duration(milliseconds: durationMs));
      }

      onPlaybackComplete?.call();
      return const Success(null);
    } catch (e) {
      return Failure(
        'Erro na reprodução da sequência',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Toca tick do metrônomo
  Future<DatabaseResult<void>> playMetronomeTick({bool isStrong = false}) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isFailure) return initResult;
    }

    try {
      final drumNote = isStrong
          ? MidiInstruments.woodBlockHigh
          : MidiInstruments.woodBlockLow;
      final velocity = isStrong ? 85 : 60; // Volume moderado

      await _midiPro.playNote(
        sfId: _percussionSoundfontId!,
        channel: 9, // Canal padrão para percussão
        key: drumNote,
        velocity: velocity,
      );

      // Parar automaticamente após duração curta
      Timer(const Duration(milliseconds: 60), () {
        _midiPro.stopNote(
          sfId: _percussionSoundfontId!,
          channel: 9,
          key: drumNote,
        );
      });

      return const Success(null);
    } catch (e) {
      return Failure(
        'Erro ao tocar metrônomo',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Para todas as notas ativas
  Future<void> stopAllNotes() async {
    if (!_isInitialized) return;

    try {
      // Parar todas as notas melódicas ativas
      for (final midiNote in _activeNotes.toList()) {
        await _midiPro.stopNote(
          sfId: _melodicSoundfontId!,
          channel: 0,
          key: midiNote,
        );
      }

      // Cancelar todos os timers
      for (final timer in _noteTimers.values) {
        timer.cancel();
      }

      _activeNotes.clear();
      _noteTimers.clear();
    } catch (e) {
      debugPrint('Erro ao parar todas as notas: $e');
    }
  }

  /// Utilitário para converter string de duração em Duration
  Duration getDurationFromString(String duration, int tempo) {
    final ms = MidiUtils.getDurationMs(duration, tempo);
    return Duration(milliseconds: ms);
  }

  /// Limpa recursos e faz dispose
  @override
  void dispose() async {
    try {
      await stopAllNotes();

      if (_melodicSoundfontId != null) {
        await _midiPro.unloadSoundfont(_melodicSoundfontId!);
        _melodicSoundfontId = null;
      }

      if (_percussionSoundfontId != null) {
        await _midiPro.unloadSoundfont(_percussionSoundfontId!);
        _percussionSoundfontId = null;
      }

      _isInitialized = false;
      MidiUtils.clearCache();

      debugPrint('🧹 UnifiedMidiService disposed successfully');
    } catch (e) {
      debugPrint('❌ Erro no dispose do UnifiedMidiService: $e');
    }
  }

  /// Factory method para usar com ServiceRegistry
  static UnifiedMidiService create() => UnifiedMidiService();

  /// Getters para verificação de estado
  bool get isInitialized => _isInitialized;
  bool get hasActiveNotes => _activeNotes.isNotEmpty;
  int get activeNotesCount => _activeNotes.length;
}