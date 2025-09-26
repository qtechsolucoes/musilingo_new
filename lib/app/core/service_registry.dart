// lib/app/core/service_registry.dart

import 'package:flutter/foundation.dart';
import 'package:musilingo/app/core/result.dart';

/// Registry centralizado para gerenciamento de dependências
/// Substitui o padrão Singleton antipattern por injeção de dependências
class ServiceRegistry {
  static final Map<Type, dynamic> _services = {};
  static final Map<Type, dynamic> _factories = {};
  static bool _isInitialized = false;

  /// Registra um serviço como singleton
  static void registerSingleton<T>(T service) {
    _services[T] = service;
    debugPrint('🔧 Serviço singleton registrado: ${T.toString()}');
  }

  /// Registra uma factory para criação de instâncias
  static void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
    debugPrint('🏭 Factory registrada: ${T.toString()}');
  }

  /// Registra uma factory lazy (criada apenas quando necessário)
  static void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = factory;
    debugPrint('💤 Lazy singleton registrado: ${T.toString()}');
  }

  /// Obtém uma instância do serviço
  static T get<T>() {
    // Primeiro, verificar se existe como singleton
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    // Verificar se existe factory
    if (_factories.containsKey(T)) {
      final factory = _factories[T] as T Function();
      final instance = factory();

      // Se é lazy singleton, armazenar para reuso
      if (!_services.containsKey(T)) {
        _services[T] = instance;
      }

      return instance;
    }

    throw ServiceNotRegisteredException(T);
  }

  /// Tenta obter um serviço, retorna null se não existir
  static T? tryGet<T>() {
    try {
      return get<T>();
    } on ServiceNotRegisteredException {
      return null;
    }
  }

  /// Verifica se um serviço está registrado
  static bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Remove um serviço do registry
  static void unregister<T>() {
    _services.remove(T);
    _factories.remove(T);
    debugPrint('🗑️ Serviço removido: ${T.toString()}');
  }

  /// Substitui um serviço existente (útil para testes)
  static void replace<T>(T newService) {
    _services[T] = newService;
    debugPrint('🔄 Serviço substituído: ${T.toString()}');
  }

  /// Inicialização dos serviços principais
  static Future<DatabaseResult<void>> initialize() async {
    if (_isInitialized) {
      return const Success(null);
    }

    try {
      debugPrint('🚀 Inicializando ServiceRegistry...');

      // Registrar serviços core
      await _registerCoreServices();

      _isInitialized = true;
      debugPrint('✅ ServiceRegistry inicializado com sucesso');

      return const Success(null);
    } catch (e) {
      debugPrint('❌ Erro ao inicializar ServiceRegistry: $e');
      return Failure(
        'Falha na inicialização dos serviços',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Registra serviços principais da aplicação
  static Future<void> _registerCoreServices() async {
    // As importações serão feitas conforme necessário para evitar ciclos
    debugPrint('📦 Registrando serviços core...');

    // Serviços serão registrados no main.dart ou onde apropriado
    // para evitar dependências circulares
  }

  /// Limpa todos os serviços - útil para testes e dispose
  static void clear() {
    debugPrint('🧹 Limpando todos os serviços...');

    // Fazer dispose dos serviços que implementam Disposable
    for (final service in _services.values) {
      if (service is Disposable) {
        try {
          service.dispose();
        } catch (e) {
          debugPrint('⚠️ Erro no dispose de ${service.runtimeType}: $e');
        }
      }
    }

    _services.clear();
    _factories.clear();
    _isInitialized = false;

    debugPrint('✅ ServiceRegistry limpo');
  }

  /// Informações de debug sobre serviços registrados
  static void printDebugInfo() {
    debugPrint('🔍 ServiceRegistry Debug Info:');
    debugPrint('  Singletons: ${_services.keys.map((t) => t.toString()).join(', ')}');
    debugPrint('  Factories: ${_factories.keys.map((t) => t.toString()).join(', ')}');
    debugPrint('  Inicializado: $_isInitialized');
  }

  /// Valida se todos os serviços críticos estão registrados
  static DatabaseResult<void> validate() {
    final criticalServices = <Type>[
      // Lista de serviços que são obrigatórios
      // Será preenchida conforme necessário
    ];

    for (final serviceType in criticalServices) {
      if (!isRegistered<dynamic>()) {
        return Failure(
          'Serviço crítico não registrado: ${serviceType.toString()}',
          errorCode: 'MISSING_CRITICAL_SERVICE',
        );
      }
    }

    return const Success(null);
  }

  // Getters para informações
  static bool get isInitialized => _isInitialized;
  static int get serviceCount => _services.length;
  static int get factoryCount => _factories.length;
}

/// Interface para serviços que precisam de cleanup
abstract class Disposable {
  void dispose();
}

/// Exception customizada para serviços não registrados
class ServiceNotRegisteredException implements Exception {
  final Type serviceType;

  ServiceNotRegisteredException(this.serviceType);

  @override
  String toString() =>
      'Serviço não registrado: ${serviceType.toString()}\n'
      'Registre o serviço usando ServiceRegistry.registerSingleton<$serviceType>() ou '
      'ServiceRegistry.registerFactory<$serviceType>()';
}