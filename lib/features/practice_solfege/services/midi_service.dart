import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class MidiService {
  static final MidiService _instance = MidiService._internal();
  factory MidiService() => _instance;
  MidiService._internal();

  final _flutterMidi = MidiPro();
  bool _isInitialized = false;
  final Map<String, int> _midiCache = {};
  int? _soundfontId;
  int? _drumSoundfontId;

  // Limite de cache para evitar memory leaks
  static const int _maxCacheSize = 100;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Carrega soundfont para piano (melodias)
      _soundfontId = await _flutterMidi.loadSoundfont(
          path: 'assets/sf2/GeneralUserGS.sf2', bank: 0, program: 0);

      // Carrega soundfont para percussão (metrônomo)
      _drumSoundfontId = await _flutterMidi.loadSoundfont(
          path: 'assets/sf2/GeneralUserGS.sf2', bank: 128, program: 0);

      _isInitialized = true;
      debugPrint('MIDI Service inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar MIDI Service: $e');
      rethrow;
    }
  }

  int noteToMidi(String note) {
    if (_midiCache.containsKey(note)) {
      return _midiCache[note]!;
    }

    final noteMap = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };

    final match = RegExp(r'([A-G])(#|b)?(\d)').firstMatch(note);
    if (match == null) return 60;

    final noteName = match.group(1)!;
    final accidental = match.group(2) ?? '';
    final octave = int.parse(match.group(3)!);

    int midiNumber = (octave + 1) * 12 + noteMap[noteName]!;

    if (accidental == '#') midiNumber += 1;
    if (accidental == 'b') midiNumber -= 1;

    // Gerenciar tamanho do cache
    if (_midiCache.length >= _maxCacheSize) {
      _midiCache.clear();
      debugPrint('MIDI cache limpo para evitar memory leak');
    }

    _midiCache[note] = midiNumber;
    return midiNumber;
  }

  Future<void> playNote(String note, {int velocity = 127}) async {
    if (!_isInitialized) await initialize();

    final midi = noteToMidi(note);
    await _flutterMidi.playNote(
        sfId: _soundfontId!, channel: 0, key: midi, velocity: velocity);
  }

  Future<void> stopNote(String note) async {
    if (!_isInitialized) return;

    final midi = noteToMidi(note);
    await _flutterMidi.stopNote(sfId: _soundfontId!, channel: 0, key: midi);
  }

  Future<void> playNoteWithDuration(String note, Duration duration,
      {int velocity = 127}) async {
    await playNote(note, velocity: velocity);

    Timer(duration, () {
      stopNote(note);
    });
  }

  Future<void> playMetronomeTick({bool isStrong = false}) async {
    if (!_isInitialized) await initialize();

    // Usar sons de blocos de madeira mais suaves
    // 77 = Wood Block High, 76 = Wood Block Low
    final drumNote = isStrong ? 77 : 76;
    final velocity = isStrong ? 100 : 70; // Mais suave

    await _flutterMidi.playNote(
        sfId: _drumSoundfontId!,
        channel: 9, // Canal de percussão
        key: drumNote,
        velocity: velocity);

    // Parar a nota após breve duração
    Timer(const Duration(milliseconds: 80), () {
      _flutterMidi.stopNote(
          sfId: _drumSoundfontId!,
          channel: 9,
          key: drumNote);
    });
  }

  Future<void> playWoodBlockTick({bool isStrong = false}) async {
    if (!_isInitialized) await initialize();

    // Sons específicos de blocos de madeira ainda mais suaves
    // 75 = Claves, 76 = Wood Block Low
    final drumNote = isStrong ? 75 : 76;
    final velocity = isStrong ? 85 : 60; // Muito suave

    await _flutterMidi.playNote(
        sfId: _drumSoundfontId!,
        channel: 9,
        key: drumNote,
        velocity: velocity);

    // Duração mais curta para som mais discreto
    Timer(const Duration(milliseconds: 60), () {
      _flutterMidi.stopNote(
          sfId: _drumSoundfontId!,
          channel: 9,
          key: drumNote);
    });
  }

  Duration getDurationFromString(String duration, int tempo) {
    final beatMs = 60000 ~/ tempo;

    final durations = {
      'whole': beatMs * 4,
      'half': beatMs * 2,
      'quarter': beatMs,
      'eighth': beatMs ~/ 2,
      'sixteenth': beatMs ~/ 4,
    };

    return Duration(milliseconds: durations[duration] ?? beatMs);
  }

  Future<void> dispose() async {
    try {
      if (_soundfontId != null) {
        await _flutterMidi.unloadSoundfont(_soundfontId!);
        _soundfontId = null;
      }
      if (_drumSoundfontId != null) {
        await _flutterMidi.unloadSoundfont(_drumSoundfontId!);
        _drumSoundfontId = null;
      }
      _midiCache.clear();
      _isInitialized = false;
      debugPrint('MIDI Service disposed successfully');
    } catch (e) {
      debugPrint('Erro ao fazer dispose do MIDI Service: $e');
    }
  }
}
