// lib/app/core/error_handler.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Sistema centralizado de tratamento de erros
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Configurações de logging
  static const bool _enableDetailedLogging = kDebugMode;
  static const bool _enableUserFriendlyMessages = true;

  /// Trata erros de forma centralizada
  static void handleError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
    bool showToUser = true,
    String? userMessage,
  }) {
    // Log detalhado para desenvolvimento
    if (_enableDetailedLogging) {
      _logDetailedError(error, context, stackTrace);
    }

    // Mensagem para o usuário
    if (_enableUserFriendlyMessages && showToUser) {
      final friendlyMessage = userMessage ?? _getFriendlyMessage(error);
      _showUserMessage(friendlyMessage);
    }

    // Reportar erro crítico se necessário
    if (_isCriticalError(error)) {
      _reportCriticalError(error, context, stackTrace);
    }
  }

  static void _logDetailedError(
      dynamic error, String? context, StackTrace? stackTrace) {
    final contextStr = context != null ? '[$context] ' : '';
    debugPrint('🚨 ERROR: $contextStr$error');

    if (stackTrace != null) {
      debugPrint('📍 STACK TRACE:');
      debugPrint(stackTrace.toString());
    }

    debugPrint('⏰ TIME: ${DateTime.now().toIso8601String()}');
    debugPrint(
        '📱 PLATFORM: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Web'}');
    debugPrint('==========================================');
  }

  static String _getFriendlyMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Erros de conexão
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection') ||
        errorStr.contains('network')) {
      return 'Problema de conexão. Verifique sua internet e tente novamente.';
    }

    // Erros de timeout
    if (errorStr.contains('timeout')) {
      return 'A operação demorou muito. Tente novamente.';
    }

    // Erros de permissão
    if (errorStr.contains('permission')) {
      return 'Permissão necessária não foi concedida.';
    }

    // Erros de autenticação
    if (errorStr.contains('auth') || errorStr.contains('unauthorized')) {
      return 'Erro de autenticação. Faça login novamente.';
    }

    // Erros de áudio
    if (errorStr.contains('audio') || errorStr.contains('microphone')) {
      return 'Problema com o áudio. Verifique as permissões do microfone.';
    }

    // Erros de arquivo
    if (errorStr.contains('file') || errorStr.contains('path')) {
      return 'Problema ao acessar arquivo. Tente novamente.';
    }

    // Erros de servidor
    if (errorStr.contains('server') ||
        errorStr.contains('500') ||
        errorStr.contains('502')) {
      return 'Problema no servidor. Tente novamente em alguns instantes.';
    }

    // Mensagem genérica
    return 'Ops! Algo deu errado. Tente novamente.';
  }

  static void _showUserMessage(String message) {
    try {
      // Para agora, apenas log da mensagem
      // Será implementado com ScaffoldMessenger quando necessário
      debugPrint('💬 USER MESSAGE: $message');
    } catch (e) {
      debugPrint('💬 USER MESSAGE (fallback): $message');
    }
  }

  static bool _isCriticalError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    return errorStr.contains('fatal') ||
        errorStr.contains('crash') ||
        errorStr.contains('outofmemory') ||
        errorStr.contains('stackoverflow');
  }

  static void _reportCriticalError(
      dynamic error, String? context, StackTrace? stackTrace) {
    // Aqui você pode integrar com serviços como Crashlytics, Sentry, etc.
    debugPrint('💥 CRITICAL ERROR DETECTED - REPORTING...');
    debugPrint('Error: $error');
    debugPrint('Context: $context');
    debugPrint('StackTrace: $stackTrace');
  }

  /// Wrapper para executar código com tratamento de erro automático
  static Future<T?> safeExecute<T>({
    required Future<T> Function() action,
    String? context,
    String? userMessage,
    T? fallbackValue,
    bool showErrorToUser = true,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      handleError(
        error,
        context: context,
        stackTrace: stackTrace,
        showToUser: showErrorToUser,
        userMessage: userMessage,
      );
      return fallbackValue;
    }
  }

  /// Wrapper para executar código síncrono com tratamento de erro
  static T? safeExecuteSync<T>({
    required T Function() action,
    String? context,
    String? userMessage,
    T? fallbackValue,
    bool showErrorToUser = true,
  }) {
    try {
      return action();
    } catch (error, stackTrace) {
      handleError(
        error,
        context: context,
        stackTrace: stackTrace,
        showToUser: showErrorToUser,
        userMessage: userMessage,
      );
      return fallbackValue;
    }
  }
}

/// Mixin para adicionar tratamento de erro a qualquer classe
mixin ErrorHandlerMixin {
  void handleError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
    bool showToUser = true,
    String? userMessage,
  }) {
    ErrorHandler.handleError(
      error,
      context: context ?? runtimeType.toString(),
      stackTrace: stackTrace,
      showToUser: showToUser,
      userMessage: userMessage,
    );
  }

  Future<T?> safeExecute<T>({
    required Future<T> Function() action,
    String? context,
    String? userMessage,
    T? fallbackValue,
    bool showErrorToUser = true,
  }) {
    return ErrorHandler.safeExecute<T>(
      action: action,
      context: context ?? runtimeType.toString(),
      userMessage: userMessage,
      fallbackValue: fallbackValue,
      showErrorToUser: showErrorToUser,
    );
  }

  T? safeExecuteSync<T>({
    required T Function() action,
    String? context,
    String? userMessage,
    T? fallbackValue,
    bool showErrorToUser = true,
  }) {
    return ErrorHandler.safeExecuteSync<T>(
      action: action,
      context: context ?? runtimeType.toString(),
      userMessage: userMessage,
      fallbackValue: fallbackValue,
      showErrorToUser: showErrorToUser,
    );
  }
}

/// Classe para tipos de erro específicos do app
class MusiLingoException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  const MusiLingoException({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => 'MusiLingoException($code): $message';
}

class AudioException extends MusiLingoException {
  const AudioException({
    required super.message,
    super.code = 'AUDIO_ERROR',
    super.originalError,
  });
}

class NetworkException extends MusiLingoException {
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

class PermissionException extends MusiLingoException {
  const PermissionException({
    required super.message,
    super.code = 'PERMISSION_ERROR',
    super.originalError,
  });
}
