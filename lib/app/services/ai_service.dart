// lib/app/services/ai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:musilingo/app/models/chat_message_model.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/core/database_error_handler.dart';
import 'package:musilingo/app/services/input_validator.dart';

class AIService {
  late final String _baseUrl;
  late final String _fallbackUrl;
  late final int _timeoutMs;
  late final int _maxRetries;
  late final int _retryDelayMs;
  final http.Client _client = http.Client();

  // Rate limiting por usuário
  final Map<String, List<DateTime>> _rateLimitMap = {};

  AIService() {
    _initializeConfig();
  }

  void _initializeConfig() {
    _baseUrl = const String.fromEnvironment('AI_BASE_URL',
        defaultValue: 'https://f91beac9eba2.ngrok-free.app');
    _fallbackUrl = const String.fromEnvironment('AI_FALLBACK_URL',
        defaultValue: 'http://localhost:5000');
    _timeoutMs =
        const int.fromEnvironment('AI_TIMEOUT_MS', defaultValue: 30000);
    _maxRetries = const int.fromEnvironment('AI_MAX_RETRIES', defaultValue: 3);
    _retryDelayMs =
        const int.fromEnvironment('AI_RETRY_DELAY_MS', defaultValue: 1000);
  }

  // Health check para verificar se o servidor está online
  Future<bool> _isServerHealthy(String url) async {
    try {
      final healthUrl = Uri.parse('$url/health');
      final response = await _client
          .get(healthUrl)
          .timeout(const Duration(milliseconds: 5000));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Método para tentar com fallback
  Future<http.Response> _makeRequest(
      Future<http.Response> Function(String) request) async {
    List<String> urls = [_baseUrl];
    if (_fallbackUrl.isNotEmpty && _fallbackUrl != _baseUrl) {
      urls.add(_fallbackUrl);
    }

    for (String url in urls) {
      if (await _isServerHealthy(url)) {
        for (int attempt = 0; attempt < _maxRetries; attempt++) {
          try {
            final response =
                await request(url).timeout(Duration(milliseconds: _timeoutMs));
            if (response.statusCode == 200) {
              return response;
            }
          } catch (e) {
            if (attempt == _maxRetries - 1) rethrow;
            await Future.delayed(Duration(milliseconds: _retryDelayMs));
          }
        }
      }
    }
    throw Exception('Todos os servidores de IA estão indisponíveis');
  }

  /// Envia o histórico de chat para o backend com validação robusta
  Future<DatabaseResult<String>> startChat(
    List<ChatMessage> messages, {
    String? userId,
  }) async {
    // VALIDAÇÃO 1: Verificar rate limiting
    if (userId != null && !InputValidator.checkRateLimit(userId, _rateLimitMap)) {
      InputValidator.logSuspiciousActivity(
        userId: userId,
        action: 'chat_rate_limit_exceeded',
        reason: 'Muitas requisições em pouco tempo',
      );
      return const Failure(
        'Muitas mensagens enviadas. Aguarde um momento.',
        errorCode: 'RATE_LIMIT_EXCEEDED',
      );
    }

    // VALIDAÇÃO 2: Validar histórico de mensagens
    final validationResult = InputValidator.validateChatHistory(messages);
    if (validationResult.isFailure) {
      if (userId != null) {
        InputValidator.logSuspiciousActivity(
          userId: userId,
          action: 'invalid_chat_input',
          reason: validationResult.errorMessage ?? 'Entrada inválida',
          content: messages.isNotEmpty ? messages.first.text : null,
        );
      }
      return Failure(
        validationResult.errorMessage ?? 'Entrada inválida',
        errorCode: 'VALIDATION_ERROR',
      );
    }

    return DatabaseErrorHandler.execute<String>(
      () async {
        // SANITIZAÇÃO: Limpar mensagens
        final history = messages
            .map((m) => {
                  'role': m.sender == MessageSender.user ? 'user' : 'model',
                  'content': InputValidator.sanitizeText(m.text),
                })
            .toList();

        final response = await _makeRequest((String baseUrl) async {
          final url = Uri.parse('$baseUrl/chat');
          return await _client.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'MusiLingo-App/1.0',
            },
            body: json.encode({
              'messages': history,
              'timestamp': DateTime.now().toIso8601String(),
              'userId': userId, // Para auditoria no servidor
            }),
          );
        });

        final body = json.decode(utf8.decode(response.bodyBytes));
        final reply = body['reply'] as String?;

        if (reply == null || reply.isEmpty) {
          throw Exception('Resposta vazia do servidor de IA');
        }

        return reply;
      },
      operationName: 'startChat',
      context: {
        'userId': userId,
        'messageCount': messages.length,
      },
    );
  }

  /// Envia um arquivo de áudio para o backend para transcrição com validação
  Future<DatabaseResult<String>> transcribeAudio(
    File audioFile, {
    String? userId,
  }) async {
    // VALIDAÇÃO 1: Verificar rate limiting
    if (userId != null && !InputValidator.checkRateLimit(userId, _rateLimitMap)) {
      InputValidator.logSuspiciousActivity(
        userId: userId,
        action: 'transcribe_rate_limit_exceeded',
        reason: 'Muitas requisições de transcrição',
      );
      return const Failure(
        'Muitas transcrições solicitadas. Aguarde um momento.',
        errorCode: 'RATE_LIMIT_EXCEEDED',
      );
    }

    // VALIDAÇÃO 2: Validar arquivo de áudio
    final validationResult = InputValidator.validateAudioFile(audioFile);
    if (validationResult.isFailure) {
      if (userId != null) {
        InputValidator.logSuspiciousActivity(
          userId: userId,
          action: 'invalid_audio_file',
          reason: validationResult.errorMessage ?? 'Arquivo inválido',
          content: audioFile.path,
        );
      }
      return Failure(
        validationResult.errorMessage ?? 'Arquivo de áudio inválido',
        errorCode: 'VALIDATION_ERROR',
      );
    }

    return DatabaseErrorHandler.execute<String>(
      () async {
        List<String> urls = [_baseUrl];
        if (_fallbackUrl.isNotEmpty && _fallbackUrl != _baseUrl) {
          urls.add(_fallbackUrl);
        }

        for (String baseUrl in urls) {
          if (await _isServerHealthy(baseUrl)) {
            for (int attempt = 0; attempt < _maxRetries; attempt++) {
              try {
                final url = Uri.parse('$baseUrl/transcribe');
                final request = http.MultipartRequest('POST', url);

                // Headers de segurança
                request.headers.addAll({
                  'User-Agent': 'MusiLingo-App/1.0',
                  'X-Timestamp': DateTime.now().toIso8601String(),
                  if (userId != null) 'X-User-ID': userId,
                });

                request.files.add(
                    await http.MultipartFile.fromPath('file', audioFile.path));

                final streamedResponse = await request
                    .send()
                    .timeout(Duration(milliseconds: _timeoutMs));
                final response = await http.Response.fromStream(streamedResponse);

                if (response.statusCode == 200) {
                  final body = json.decode(utf8.decode(response.bodyBytes));
                  final musicXml = body['musicxml'] as String?;

                  if (musicXml == null || musicXml.isEmpty) {
                    throw Exception('MusicXML vazio retornado do servidor');
                  }

                  return musicXml;
                } else {
                  throw Exception('Servidor retornou status ${response.statusCode}');
                }
              } catch (e) {
                if (attempt == _maxRetries - 1) rethrow;
                await Future.delayed(Duration(milliseconds: _retryDelayMs));
              }
            }
          }
        }
        throw Exception('Todos os servidores de transcrição estão indisponíveis');
      },
      operationName: 'transcribeAudio',
      context: {
        'userId': userId,
        'fileName': audioFile.path.split('/').last,
        'fileSize': audioFile.lengthSync(),
      },
    );
  }

  /// Limpa rate limits antigos (deve ser chamado periodicamente)
  void cleanupRateLimits() {
    final now = DateTime.now();
    _rateLimitMap.removeWhere((userId, requests) {
      requests.removeWhere((time) => now.difference(time).inMinutes >= 1);
      return requests.isEmpty;
    });
  }

  void dispose() {
    _client.close();
    _rateLimitMap.clear();
  }
}
