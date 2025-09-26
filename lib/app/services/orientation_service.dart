// lib/app/services/orientation_service.dart

import 'package:flutter/services.dart';

/// Serviço centralizado para gerenciamento de orientação de tela
/// Evita conflitos e garante controle consistente da orientação
class OrientationService {
  static final OrientationService _instance = OrientationService._internal();
  factory OrientationService() => _instance;
  OrientationService._internal();

  static OrientationService get instance => _instance;

  List<DeviceOrientation> _currentPreferences = DeviceOrientation.values;
  final List<String> _orientationStack = [];

  /// Define orientação para uma tela específica
  Future<void> setOrientation(
    List<DeviceOrientation> orientations,
    String screenId,
  ) async {
    _currentPreferences = orientations;
    _orientationStack.add(screenId);

    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Remove orientação de uma tela específica e restaura a anterior
  Future<void> removeOrientation(String screenId) async {
    _orientationStack.remove(screenId);

    // Se não há mais restrições específicas, libera todas as orientações
    if (_orientationStack.isEmpty) {
      _currentPreferences = DeviceOrientation.values;
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else {
      // Mantém a orientação da tela anterior na pilha
      // Por simplicidade, manteremos a atual se há outras telas na pilha
      await SystemChrome.setPreferredOrientations(_currentPreferences);
    }
  }

  /// Força orientação landscape para exercícios
  Future<void> setLandscapeMode(String screenId) async {
    await setOrientation([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ], screenId);
  }

  /// Força orientação portrait para interfaces regulares
  Future<void> setPortraitMode(String screenId) async {
    await setOrientation([
      DeviceOrientation.portraitUp,
    ], screenId);
  }

  /// Libera todas as orientações
  Future<void> setFreeOrientation(String screenId) async {
    await setOrientation(DeviceOrientation.values, screenId);
  }

  /// Orientações específicas para exercícios musicais
  Future<void> setMusicExerciseMode(String screenId) async {
    await setLandscapeMode(screenId);
  }

  /// Orientações para visualização de partituras
  Future<void> setScoreViewMode(String screenId) async {
    await setLandscapeMode(screenId);
  }

  /// Restaura orientação padrão do sistema
  Future<void> resetToSystemDefault() async {
    _orientationStack.clear();
    _currentPreferences = DeviceOrientation.values;
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  /// Getter para orientações atuais (útil para debug)
  List<DeviceOrientation> get currentOrientations => _currentPreferences;

  /// Getter para pilha de orientações (útil para debug)
  List<String> get orientationStack => List.unmodifiable(_orientationStack);
}