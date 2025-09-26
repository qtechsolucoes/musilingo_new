import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/app/core/service_registry.dart';

// Circular buffer otimizado para evitar memory leaks
class CircularAudioBuffer {
  final List<double> _buffer;
  final int _maxSize;
  int _writeIndex = 0;
  int _currentSize = 0;

  CircularAudioBuffer(this._maxSize) : _buffer = List.filled(_maxSize, 0.0);

  void addSample(double sample) {
    _buffer[_writeIndex] = sample;
    _writeIndex = (_writeIndex + 1) % _maxSize;
    if (_currentSize < _maxSize) _currentSize++;
  }

  List<double> getLatestSamples(int count) {
    if (count > _currentSize) return [];

    final startIndex = (_writeIndex - count + _maxSize) % _maxSize;
    final result = <double>[];

    for (int i = 0; i < count; i++) {
      result.add(_buffer[(startIndex + i) % _maxSize]);
    }

    return result;
  }

  List<double> getAllSamples() => getLatestSamples(_currentSize);

  void clear() {
    _writeIndex = 0;
    _currentSize = 0;
  }

  int get length => _currentSize;
  bool get isEmpty => _currentSize == 0;
  bool get isNotEmpty => _currentSize > 0;
}

class AudioAnalysisService implements Disposable {
  // CORREÇÃO: Removido padrão Singleton

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  PitchDetector? _pitchDetector;

  StreamController<AudioAnalysisData>? _analysisController;
  StreamSubscription? _recordingDataSubscription;
  Timer? _analysisTimer;

  bool _isRecording = false;
  bool _isInitialized = false;

  late CircularAudioBuffer _audioBuffer;
  String _lastDetectedWord = '';
  DateTime? _noteStartTime;

  static const int sampleRate = 44100;
  static const int bufferSize = 2048;

  // Tolerância para detecção de duração e afinação
  static const double durationTolerance = 0.2;
  // A tolerância do pitch agora é uma porcentagem, mais próxima
  // da percepção musical. 5% = +/- 1 semitom, que é uma boa tolerância.
  static const double pitchTolerancePercentage = 0.05;
  // Limiar mínimo de amplitude para considerar que há som vocal
  static const double basePitchTolerance = 0.03; // Base científica de 3%

  // Getters necessários para compatibilidade
  bool get isInitialized => _isInitialized;

  Stream<AudioAnalysisData> get audioDataStream {
    if (_analysisController == null) {
      throw Exception('AudioAnalysisService não foi iniciado');
    }
    return _analysisController!.stream;
  }

  // Métodos de conveniência para compatibilidade
  Future<void> startAnalysis() async {
    start();
  }

  Future<void> stopAnalysis() async {
    await stop();
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final microphoneStatus = await Permission.microphone.request();
      if (!microphoneStatus.isGranted) {
        throw Exception('Permissão de microfone negada');
      }

      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );

      _pitchDetector = PitchDetector(
          audioSampleRate: sampleRate.toDouble(), bufferSize: bufferSize);

      _audioBuffer = CircularAudioBuffer(bufferSize * 2);

      final available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
        debugLogging: true,
      );

      if (!available) {
        debugPrint('Speech recognition não disponível');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Erro ao inicializar AudioAnalysisService: $e');
      return false;
    }
  }

  Stream<AudioAnalysisData> start() {
    if (!_isInitialized) {
      throw Exception(
          "AudioAnalysisService not initialized. Call initialize() first.");
    }

    _analysisController = StreamController<AudioAnalysisData>.broadcast();
    _audioBuffer.clear();
    _noteStartTime = DateTime.now();
    _lastDetectedWord = '';

    final recordingDataController = StreamController<Uint8List>();

    _recorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
    );

    if (_speech.isAvailable) {
      _speech.listen(
        onResult: (result) {
          _lastDetectedWord = result.recognizedWords.toLowerCase();
          debugPrint(
              'Speech detectado: "${result.recognizedWords}" (confiança: ${result.confidence})');
        },
        localeId: 'pt_BR',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
          onDevice: false,
        ),
      );
    }

    _isRecording = true;

    _recordingDataSubscription = recordingDataController.stream.listen(
      (data) {
        _processAudioData(data);
      },
      onError: (error) {
        debugPrint('Erro no stream de áudio: $error');
      },
      onDone: () {
        recordingDataController.close();
      },
    );

    _analysisTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      if (_audioBuffer.length >= bufferSize) {
        _analyzeBuffer().then((analysis) {
          if (_analysisController != null && !_analysisController!.isClosed) {
            _analysisController!.add(analysis);
          }
        }).catchError((error) {
          debugPrint('Erro na análise de áudio: $error');
        });
      }
    });

    return _analysisController!.stream;
  }

  void _processAudioData(Uint8List data) {
    for (int i = 0; i < data.length - 1; i += 2) {
      int sample = data[i] | (data[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      final normalizedSample = sample / 32768.0;
      _audioBuffer.addSample(normalizedSample);
    }
  }

  Future<AudioAnalysisData> _analyzeBuffer() async {
    double detectedFrequency = 0;
    double confidence = 0.0;

    if (_pitchDetector != null && _audioBuffer.length >= bufferSize) {
      try {
        final sample = _audioBuffer.getLatestSamples(bufferSize);
        final result = await _pitchDetector!.getPitchFromFloatBuffer(sample);

        if (result.pitched) {
          detectedFrequency = result.pitch;
          confidence = result.probability;
        }
      } catch (e) {
        debugPrint('Erro ao detectar pitch: $e');
      }
    }

    final currentDuration = _noteStartTime != null
        ? DateTime.now().difference(_noteStartTime!).inMilliseconds / 1000.0
        : 0.0;

    double amplitude = 0;
    if (_audioBuffer.isNotEmpty) {
      final samples = _audioBuffer.getAllSamples();
      double sum = 0;
      for (final sample in samples) {
        sum += sample * sample;
      }
      amplitude = math.sqrt(sum / samples.length);
    }

    return AudioAnalysisData(
        frequency: detectedFrequency,
        amplitude: amplitude,
        detectedWord: _lastDetectedWord,
        currentDuration: currentDuration,
        confidence: confidence,
        pitch: detectedFrequency);
  }

  void resetNoteTimer() {
    _noteStartTime = DateTime.now();
    _lastDetectedWord = '';
  }

  Future<void> stop() async {
    if (!_isRecording) return;
    _isRecording = false;

    try {
      // Cancel timer first
      _analysisTimer?.cancel();
      _analysisTimer = null;

      // Stop recording
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }

      // Stop speech recognition
      if (_speech.isAvailable && _speech.isListening) {
        await _speech.stop();
      }

      // Cancel subscription
      await _recordingDataSubscription?.cancel();
      _recordingDataSubscription = null;

      // Close analysis controller
      if (_analysisController != null && !_analysisController!.isClosed) {
        await _analysisController!.close();
      }
      _analysisController = null;

      // Clear buffers
      _audioBuffer.clear();
      _lastDetectedWord = '';
      _noteStartTime = null;

      debugPrint('AudioAnalysisService stopped successfully');
    } catch (e) {
      debugPrint('Erro ao parar AudioAnalysisService: $e');
    }
  }

  bool checkPitch(double expectedFrequency, double detectedFrequency,
      {double? amplitude}) {
    if (detectedFrequency <= 0 || expectedFrequency <= 0) return false;

    // CORREÇÃO 1: Amplitude adaptativa por região de frequência
    if (amplitude != null) {
      final adaptiveThreshold =
          _getAdaptiveAmplitudeThreshold(detectedFrequency);
      if (amplitude < adaptiveThreshold) return false;
    }

    // CORREÇÃO 2: Algoritmo matemático O(1) em vez de O(n) loop
    final octaveRatio = detectedFrequency / expectedFrequency;
    final logRatio = math.log(octaveRatio) / math.log(2);
    final nearestOctave = (logRatio + 0.5).floor();
    final correctedFrequency = expectedFrequency * math.pow(2, nearestOctave);

    // CORREÇÃO 3: Tolerância adaptativa por região
    final adaptiveTolerance = _getAdaptiveTolerance(correctedFrequency);
    final frequencyDifference = (detectedFrequency - correctedFrequency).abs();

    return frequencyDifference <= adaptiveTolerance;
  }

  double _getAdaptiveAmplitudeThreshold(double frequency) {
    // Vozes graves precisam de threshold menor
    if (frequency < 200) return 0.008; // Vozes masculinas graves
    if (frequency < 400) return 0.012; // Vozes masculinas médias
    return 0.015; // Vozes agudas
  }

  double _getAdaptiveTolerance(double frequency) {
    // Tolerância percentual adaptativa baseada em pesquisa científica
    final frequencyFactor = 1.0 + (frequency / 1000.0) * 0.02;
    return frequency * basePitchTolerance * frequencyFactor;
  }

  bool checkDuration(double expectedDuration, double actualDuration) {
    return (actualDuration - expectedDuration).abs() <= durationTolerance;
  }

  bool checkNoteName(String expected, String detected) {
    if (detected.isEmpty) return false;

    final expectedLower = expected
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o');
    final detectedLower = detected
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o');

    // Melhorar a precisão da detecção de nome, considerando palavras-chave
    if (expectedLower.contains('do') && detectedLower.contains('do')) {
      return true;
    }
    if (expectedLower.contains('re') && detectedLower.contains('re')) {
      return true;
    }
    if (expectedLower.contains('mi') && detectedLower.contains('mi')) {
      return true;
    }
    if (expectedLower.contains('fa') && detectedLower.contains('fa')) {
      return true;
    }
    if (expectedLower.contains('sol') && detectedLower.contains('sol')) {
      return true;
    }
    if (expectedLower.contains('la') && detectedLower.contains('la')) {
      return true;
    }
    if (expectedLower.contains('si') && detectedLower.contains('si')) {
      return true;
    }

    return false;
  }

  @override
  void dispose() async {
    try {
      await stop();

      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }

      await _recorder.closeRecorder();

      _isInitialized = false;
      debugPrint('🧹 AudioAnalysisService disposed successfully');
    } catch (e) {
      debugPrint('Erro ao fazer dispose do AudioAnalysisService: $e');
    }
  }

  /// Factory method para usar com ServiceRegistry
  static AudioAnalysisService create() => AudioAnalysisService();
}
