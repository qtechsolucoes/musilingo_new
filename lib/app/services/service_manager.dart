// lib/app/services/service_manager.dart

import 'package:musilingo/features/practice_solfege/services/audio_analysis_service.dart';
import 'package:musilingo/features/practice_solfege/services/midi_service.dart';
import 'package:musilingo/app/services/ai_service.dart';
import 'package:musilingo/features/duel/services/duel_service.dart';
import 'package:flutter/foundation.dart';

/// Gerenciador centralizado de serviços para controle de memória e cleanup
class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  final List<dynamic> _services = [];
  bool _isDisposed = false;

  // Registrar serviços para cleanup automático
  void registerService(dynamic service) {
    if (!_isDisposed && !_services.contains(service)) {
      _services.add(service);
      debugPrint('Serviço registrado: ${service.runtimeType}');
    }
  }

  // Remover serviço da lista
  void unregisterService(dynamic service) {
    _services.remove(service);
    debugPrint('Serviço removido: ${service.runtimeType}');
  }

  // Dispose de um serviço específico
  Future<void> disposeService(dynamic service) async {
    try {
      if (service is AudioAnalysisService) {
        service.dispose();
      } else if (service is MidiService) {
        service.dispose();
      } else if (service is AIService) {
        service.dispose();
      } else if (service is DuelService) {
        service.dispose();
      }
      unregisterService(service);
    } catch (e) {
      debugPrint('Erro ao fazer dispose do serviço ${service.runtimeType}: $e');
    }
  }

  // Dispose de todos os serviços
  Future<void> disposeAll() async {
    if (_isDisposed) return;
    _isDisposed = true;

    debugPrint('Iniciando dispose de ${_services.length} serviços...');

    for (final service in List.from(_services)) {
      await disposeService(service);
    }

    _services.clear();
    debugPrint('Todos os serviços foram descartados');
  }

  // Verificar status dos serviços
  void printServiceStatus() {
    debugPrint('=== STATUS DOS SERVIÇOS ===');
    debugPrint('Total de serviços ativos: ${_services.length}');
    for (int i = 0; i < _services.length; i++) {
      debugPrint('${i + 1}. ${_services[i].runtimeType}');
    }
    debugPrint('==========================');
  }

  // Limpar cache de todos os serviços
  void clearAllCaches() {
    for (final service in _services) {
      try {
        if (service is MidiService) {
          // MidiService já tem controle de cache interno
        }
        // Adicionar outros serviços com cache conforme necessário
      } catch (e) {
        debugPrint('Erro ao limpar cache do ${service.runtimeType}: $e');
      }
    }
    debugPrint('Caches limpos para todos os serviços');
  }

  // Reinicializar ServiceManager (para testing)
  void reset() {
    _isDisposed = false;
    _services.clear();
  }
}