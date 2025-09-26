// ==========================================
// audio_processor.dart - Processamento de Áudio
// ==========================================
import 'dart:typed_data';
import 'dart:math' as math;

class AudioProcessor {
  // Converter Int16List para List<double>
  static List<double> int16ToFloat(Int16List samples) {
    return samples.map((s) => s / 32768.0).toList();
  }

  // Converter Uint8List para List<double> - VERSÃO OTIMIZADA
  static List<double> uint8ToFloat(Uint8List bytes) {
    if (bytes.length < 2) return [];

    final sampleCount = bytes.length ~/ 2;
    final samples = List<double>.filled(sampleCount, 0.0); // Pre-aloca tamanho
    final data = ByteData.sublistView(bytes);

    for (int i = 0, j = 0; i < bytes.length - 1; i += 2, j++) {
      int sample = data.getInt16(i, Endian.little);
      samples[j] = sample / 32768.0;
    }
    return samples;
  }

  // Calcular RMS (Root Mean Square) - volume
  static double calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    return math.sqrt(sum / samples.length);
  }

  // Converter RMS para decibéis
  static double rmsToDb(double rms) {
    if (rms <= 0) return -100.0; // Silêncio absoluto
    return 20 * math.log(rms) / math.ln10;
  }

  // Detectar se há som significativo
  static bool hasSound(List<double> samples, {double threshold = 0.01}) {
    double rms = calculateRMS(samples);
    return rms > threshold;
  }

  // Aplicar filtro de suavização
  static List<double> smoothSignal(List<double> samples, {int windowSize = 5}) {
    if (samples.length < windowSize) return samples;
    List<double> smoothed = [];
    for (int i = 0; i < samples.length; i++) {
      int start = math.max(0, i - windowSize ~/ 2);
      int end = math.min(samples.length, i + windowSize ~/ 2 + 1);
      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += samples[j];
      }
      smoothed.add(sum / (end - start));
    }
    return smoothed;
  }

  // Detectar picos no sinal
  static List<int> detectPeaks(List<double> samples, {double threshold = 0.3}) {
    List<int> peaks = [];
    for (int i = 1; i < samples.length - 1; i++) {
      if (samples[i] > threshold &&
          samples[i] > samples[i - 1] &&
          samples[i] > samples[i + 1]) {
        peaks.add(i);
      }
    }
    return peaks;
  }

  // Normalizar volume
  static List<double> normalize(List<double> samples,
      {double targetLevel = 0.7}) {
    if (samples.isEmpty) return samples;

    double maxAbs = 0;
    for (var sample in samples) {
      double abs = sample.abs();
      if (abs > maxAbs) maxAbs = abs;
    }
    if (maxAbs == 0) return samples;
    double factor = targetLevel / maxAbs;
    return samples.map((s) => s * factor).toList();
  }

  // Pool de buffers reutilizáveis para evitar allocations constantes
  static final Map<int, List<List<double>>> _bufferPool = {};
  static const int _maxPoolSize = 5;

  static List<double> getBuffer(int size) {
    if (_bufferPool.containsKey(size) && _bufferPool[size]!.isNotEmpty) {
      final buffer = _bufferPool[size]!.removeLast();
      buffer.fillRange(0, buffer.length, 0.0);
      return buffer;
    }
    return List<double>.filled(size, 0.0);
  }

  static void returnBuffer(List<double> buffer) {
    final size = buffer.length;
    _bufferPool[size] ??= <List<double>>[];
    if (_bufferPool[size]!.length < _maxPoolSize) {
      _bufferPool[size]!.add(buffer);
    }
  }

  static void clearBufferPool() {
    _bufferPool.clear();
  }
}
