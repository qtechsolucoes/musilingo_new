// lib/app/services/input_validator.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/models/chat_message_model.dart';

/// Validador de inputs com regras de segurança
class InputValidator {
  // Limites de segurança
  static const int maxMessageLength = 2000;
  static const int maxMessagesInHistory = 50;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedAudioFormats = [
    '.wav',
    '.mp3',
    '.m4a',
    '.aac'
  ];

  /// Valida histórico de mensagens de chat
  static Result<List<ChatMessage>> validateChatHistory(
      List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return const Failure(
        'Histórico de mensagens não pode estar vazio.',
        errorCode: 'EMPTY_MESSAGES',
      );
    }

    if (messages.length > maxMessagesInHistory) {
      return const Failure(
        'Muitas mensagens no histórico (máximo: $maxMessagesInHistory).',
        errorCode: 'TOO_MANY_MESSAGES',
      );
    }

    // Validar cada mensagem
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageValidation = _validateSingleMessage(message, i);
      if (messageValidation.isFailure) {
        return messageValidation as Result<List<ChatMessage>>;
      }
    }

    return Success(messages);
  }

  /// Valida uma mensagem individual
  static Result<ChatMessage> _validateSingleMessage(
      ChatMessage message, int index) {
    if (message.text.isEmpty) {
      return Failure(
        'Mensagem #${index + 1} está vazia.',
        errorCode: 'EMPTY_MESSAGE',
      );
    }

    if (message.text.length > maxMessageLength) {
      return Failure(
        'Mensagem #${index + 1} muito longa (máximo: $maxMessageLength caracteres).',
        errorCode: 'MESSAGE_TOO_LONG',
      );
    }

    // Verificar conteúdo suspeito
    final suspiciousContent = _detectSuspiciousContent(message.text);
    if (suspiciousContent != null) {
      return Failure(
        'Mensagem #${index + 1} contém conteúdo inadequado: $suspiciousContent',
        errorCode: 'SUSPICIOUS_CONTENT',
      );
    }

    return Success(message);
  }

  /// Sanitiza texto removendo caracteres perigosos
  static String sanitizeText(String input) {
    if (input.isEmpty) return '';

    // Remove caracteres de controle
    String sanitized = input.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');

    // Remove sequências de escape ANSI
    sanitized = sanitized.replaceAll(RegExp(r'\x1B\[[0-9;]*[mK]'), '');

    // Limita tamanho
    if (sanitized.length > maxMessageLength) {
      sanitized = sanitized.substring(0, maxMessageLength);
    }

    // Escape para JSON
    sanitized = sanitized
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');

    return sanitized.trim();
  }

  /// Valida arquivo de áudio
  static Result<File> validateAudioFile(File audioFile) {
    // Verificar se o arquivo existe
    if (!audioFile.existsSync()) {
      return const Failure(
        'Arquivo de áudio não encontrado.',
        errorCode: 'FILE_NOT_FOUND',
      );
    }

    // Verificar extensão do arquivo
    final fileName = audioFile.path.toLowerCase();
    final isValidFormat =
        allowedAudioFormats.any((format) => fileName.endsWith(format));

    if (!isValidFormat) {
      return Failure(
        'Formato de áudio não suportado. Formatos válidos: ${allowedAudioFormats.join(', ')}',
        errorCode: 'INVALID_AUDIO_FORMAT',
      );
    }

    // Verificar tamanho do arquivo
    try {
      final fileSize = audioFile.lengthSync();
      if (fileSize > maxFileSize) {
        return Failure(
          'Arquivo muito grande. Tamanho máximo: ${(maxFileSize / 1024 / 1024).toStringAsFixed(1)}MB',
          errorCode: 'FILE_TOO_LARGE',
        );
      }

      if (fileSize == 0) {
        return const Failure(
          'Arquivo de áudio está vazio.',
          errorCode: 'EMPTY_FILE',
        );
      }
    } catch (e) {
      return Failure(
        'Erro ao verificar arquivo: ${e.toString()}',
        errorCode: 'FILE_ACCESS_ERROR',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }

    return Success(audioFile);
  }

  /// Detecta conteúdo suspeito ou malicioso
  static String? _detectSuspiciousContent(String text) {
    text.toLowerCase();

    // Padrões suspeitos
    final suspiciousPatterns = [
      // Injection attempts
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript\s*:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),

      // SQL injection
      RegExp(r'(union|select|insert|update|delete|drop)\s+',
          caseSensitive: false),
      RegExp(r';\s*(drop|truncate|delete)', caseSensitive: false),

      // Command injection
      RegExp(r'[;&|`$]\s*(rm|del|format|shutdown)', caseSensitive: false),

      // Path traversal
      RegExp(r'\.\.[/\\]'),

      // Excessivamente repetitivo (spam)
      RegExp(r'(.)\1{50,}'), // Mesmo caractere repetido 50+ vezes
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(text)) {
        return 'Padrão suspeito detectado';
      }
    }

    // Verificar URLs suspeitas
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final urls = urlPattern.allMatches(text);

    for (final match in urls) {
      final url = match.group(0)!.toLowerCase();
      // Lista básica de domínios suspeitos
      final suspiciousDomains = ['bit.ly', 'tinyurl.com', 't.co'];

      if (suspiciousDomains.any((domain) => url.contains(domain))) {
        return 'URL encurtada detectada';
      }
    }

    return null; // Conteúdo seguro
  }

  /// Valida rate limiting simples
  static bool checkRateLimit(
      String userId, Map<String, List<DateTime>> rateLimitMap) {
    const maxRequestsPerMinute = 10;
    final now = DateTime.now();
    final userRequests = rateLimitMap[userId] ?? [];

    // Remove requests antigas (mais de 1 minuto)
    userRequests.removeWhere((time) => now.difference(time).inMinutes >= 1);

    if (userRequests.length >= maxRequestsPerMinute) {
      return false; // Rate limit exceeded
    }

    // Adiciona request atual
    userRequests.add(now);
    rateLimitMap[userId] = userRequests;

    return true; // OK to proceed
  }

  /// Log de auditoria para ações suspeitas
  static void logSuspiciousActivity({
    required String userId,
    required String action,
    required String reason,
    String? content,
  }) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'action': action,
      'reason': reason,
      'content': content?.substring(0, 100), // Primeiros 100 chars apenas
      'severity': 'WARNING',
    };

    debugPrint('🚨 SUSPICIOUS ACTIVITY: ${logEntry.toString()}');

    // Em produção, enviar para sistema de monitoramento
    // _sendToSecurityLog(logEntry);
  }
}
