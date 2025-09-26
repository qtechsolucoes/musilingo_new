// ==========================================
// lib/app/utils/test_audio_service.dart - Testes para Debug
// ==========================================
import 'dart:math' as math;
import 'package:flutter/foundation.dart'; // Para usar o debugPrint

class TestAudioService {
  // Gerar tom de teste para calibração
  static List<double> generateTestTone(
    double frequency,
    int sampleRate,
    Duration duration,
  ) {
    int numSamples = (sampleRate * duration.inMilliseconds / 1000).round();
    List<double> samples = [];

    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      double sample = math.sin(2 * math.pi * frequency * t);
      samples.add(sample);
    }

    return samples;
  }

  // Testar detecção com frequência conhecida
  // A função pitchDetector deve ser uma função que recebe List<double> e retorna Future<double>
  static Future<bool> testPitchDetection(
    Future<double> Function(List<double>) pitchDetector,
    double expectedFrequency,
  ) async {
    // Gerar tom de teste
    List<double> testSamples = generateTestTone(
      expectedFrequency,
      44100, // Sample rate comum
      const Duration(milliseconds: 500),
    );

    // Detectar pitch
    double detectedFrequency = await pitchDetector(testSamples);

    // Verificar precisão (tolerância de 2%)
    double error =
        (detectedFrequency - expectedFrequency).abs() / expectedFrequency;
    bool isAccurate = error < 0.02;

    if (kDebugMode) {
      debugPrint('[TEST] Esperado: ${expectedFrequency.toStringAsFixed(2)}Hz');
      debugPrint('[TEST] Detectado: ${detectedFrequency.toStringAsFixed(2)}Hz');
      debugPrint('[TEST] Erro: ${(error * 100).toStringAsFixed(2)}%');
      debugPrint('[TEST] Status: ${isAccurate ? "✓ PASSOU" : "✗ FALHOU"}');
    }

    return isAccurate;
  }

  // Executar bateria de testes
  static Future<void> runAllTests(
      Future<double> Function(List<double>) pitchDetector) async {
    if (kDebugMode) {
      debugPrint('========== INICIANDO TESTES DE DETECÇÃO DE PITCH ==========');
    }

    // Testar notas comuns
    const Map<String, double> testNotes = {
      'Dó4': 261.63,
      'Ré4': 293.66,
      'Mi4': 329.63,
      'Fá4': 349.23,
      'Sol4': 392.00,
      'Lá4': 440.00,
      'Si4': 493.88,
      'Dó5': 523.25,
    };

    int passed = 0;
    int total = testNotes.length;

    for (var entry in testNotes.entries) {
      if (kDebugMode) {
        debugPrint('\nTestando ${entry.key}:');
      }
      bool result = await testPitchDetection(pitchDetector, entry.value);
      if (result) passed++;
    }

    if (kDebugMode) {
      debugPrint('\n========== RESULTADO DOS TESTES ==========');
      debugPrint('Passou: $passed/$total');
      debugPrint(
          'Taxa de sucesso: ${(passed / total * 100).toStringAsFixed(1)}%');
    }
  }
}
