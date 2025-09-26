// lib/features/duel/services/duel_service.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:musilingo/main.dart';
import 'package:musilingo/features/duel/data/models/duel_models.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/core/database_error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DuelService {
  final _supabase = supabase;
  String? currentDuelId;
  RealtimeChannel? _duelChannel;

  final _duelController = StreamController<Duel?>.broadcast();
  Stream<Duel?> get duelStream => _duelController.stream;

  final _participantsController =
      StreamController<List<DuelParticipant>>.broadcast();
  Stream<List<DuelParticipant>> get participantsStream =>
      _participantsController.stream;

  final _questionsController = StreamController<List<DuelQuestion>>.broadcast();
  Stream<List<DuelQuestion>> get questionsStream => _questionsController.stream;

  // Sistema de reconexão
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _reconnectDelay = 2000; // ms
  Timer? _reconnectTimer;

  // Status de conectividade
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Busca ou cria um duelo de forma atômica para evitar race conditions
  Future<DatabaseResult<String>> findOrCreateDuel(String userId) async {
    // Validação de entrada
    final validation = DatabaseErrorHandler.validateInput(userId: userId);
    if (validation.isFailure) {
      return validation as DatabaseResult<String>;
    }

    return DatabaseErrorHandler.execute<String>(
      () async {
        const maxRetries = 3;
        int retryCount = 0;

        while (retryCount < maxRetries) {
          try {
            // CORREÇÃO: Usar stored procedure atômica
            final result = await _supabase.rpc('find_or_create_duel_atomic',
                params: {'p_user_id': userId});

            if (result == null) {
              throw Exception('Resposta nula da stored procedure');
            }

            // Verificar se houve erro na stored procedure
            if (result['error'] != null) {
              debugPrint('Erro na stored procedure: ${result['error']}');
              retryCount++;
              if (retryCount >= maxRetries) {
                throw Exception(result['error']);
              }
              // Retry com backoff exponencial
              await Future.delayed(
                  Duration(milliseconds: 100 * pow(2, retryCount).toInt()));
              continue;
            }

            final duelId = result['duel_id'] as String?;
            if (duelId == null) {
              throw Exception('ID do duelo não retornado');
            }

            currentDuelId = duelId;
            final wasCreated = result['was_created'] as bool? ?? false;

            // Se duelo foi criado, gerar questões
            if (wasCreated) {
              final questionsResult = await _generateDuelQuestions(duelId);
              if (questionsResult.isFailure) {
                debugPrint(
                    'Erro ao gerar questões: ${questionsResult.errorMessage}');
                // Continuar mesmo se falhar na geração de questões
              }
            }

            // Iniciar listening para atualizações
            listenToDuelUpdates(duelId);

            debugPrint(
                '✅ Duelo ${wasCreated ? 'criado' : 'encontrado'}: $duelId');
            return duelId;
          } catch (e) {
            retryCount++;
            debugPrint('Tentativa $retryCount falhou: $e');

            if (retryCount >= maxRetries) {
              rethrow;
            }

            // Backoff exponencial
            await Future.delayed(
                Duration(milliseconds: 100 * pow(2, retryCount).toInt()));
          }
        }

        throw Exception('Máximo de tentativas excedido');
      },
      operationName: 'findOrCreateDuel',
      context: {'userId': userId},
    );
  }

  Future<DatabaseResult<void>> _generateDuelQuestions(String duelId) async {
    return DatabaseErrorHandler.execute<void>(
      () async {
        // Verificar se as perguntas já existem para evitar duplicação
        final existingQuestions = await _supabase
            .from('duel_questions')
            .select('id')
            .eq('duel_id', duelId);

        if (existingQuestions.isNotEmpty) {
          debugPrint('Perguntas já existem para duelo $duelId');
          return;
        }

        final List<Map<String, dynamic>> questions = [
          {
            'duel_id': duelId,
            'question_text':
                'Qual nota está na terceira linha da clave de Sol?',
            'options': ['Sol', 'Si', 'Ré', 'Fá'],
            'correct_answer': 'Si'
          },
          {
            'duel_id': duelId,
            'question_text': 'Quantos tempos dura uma semínima?',
            'options': ['1 tempo', '2 tempos', '4 tempos', 'Meio tempo'],
            'correct_answer': '1 tempo'
          },
          {
            'duel_id': duelId,
            'question_text': 'O que significa "piano" em dinâmica musical?',
            'options': [
              'Tocar forte',
              'Tocar rápido',
              'Tocar suave',
              'Tocar devagar'
            ],
            'correct_answer': 'Tocar suave'
          },
        ];

        await _supabase.from('duel_questions').insert(questions);
        debugPrint('✅ Perguntas geradas para duelo $duelId');
      },
      operationName: '_generateDuelQuestions',
      context: {'duelId': duelId},
    );
  }

  /// Submete resposta com validação robusta
  Future<DatabaseResult<void>> submitAnswer(
      String questionId, String answer, String userId) async {
    // Validação de entrada
    final validation = DatabaseErrorHandler.validateInput(userId: userId);
    if (validation.isFailure) {
      return validation;
    }

    if (questionId.trim().isEmpty) {
      return const Failure(
        'ID da pergunta não pode estar vazio.',
        errorCode: 'INVALID_QUESTION_ID',
      );
    }

    if (answer.trim().isEmpty) {
      return const Failure(
        'Resposta não pode estar vazia.',
        errorCode: 'EMPTY_ANSWER',
      );
    }

    return DatabaseErrorHandler.execute<void>(
      () async {
        await _supabase.rpc('submit_duel_answer', params: {
          'p_question_id': questionId,
          'p_user_id': userId,
          'p_answer': answer.trim()
        });
      },
      operationName: 'submitAnswer',
      context: {
        'questionId': questionId,
        'userId': userId,
        'answer': answer,
      },
    );
  }

  // ==================== SISTEMA DE RECONEXÃO MELHORADO ====================
  void listenToDuelUpdates(String duelId) {
    _setupRealtimeConnection(duelId);
  }

  void _setupRealtimeConnection(String duelId) {
    try {
      _duelChannel = _supabase.channel('duel_room_$duelId');

      _duelChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'duels',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: duelId,
            ),
            callback: (payload) =>
                _handleRealtimeUpdate(() => _fetchDuelAndParticipants(duelId)),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'duel_participants',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'duel_id',
              value: duelId,
            ),
            callback: (payload) =>
                _handleRealtimeUpdate(() => _fetchDuelAndParticipants(duelId)),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'duel_questions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'duel_id',
              value: duelId,
            ),
            callback: (payload) =>
                _handleRealtimeUpdate(() => _fetchQuestions(duelId)),
          )
          .subscribe((status, [ref]) async {
        _handleConnectionStatusChange(status, duelId);
      });
    } catch (e) {
      debugPrint('Erro ao configurar conexão Realtime: $e');
      _scheduleReconnection(duelId);
    }
  }

  void _handleConnectionStatusChange(
      RealtimeSubscribeStatus status, String duelId) async {
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _reconnectAttempts = 0;
        _connectivityController.add(true);
        debugPrint('✅ Conectado ao Realtime para duelo $duelId');

        // Buscar dados iniciais
        await _fetchDuelAndParticipants(duelId);
        await _fetchQuestions(duelId);
        break;

      case RealtimeSubscribeStatus.channelError:
      case RealtimeSubscribeStatus.timedOut:
        _connectivityController.add(false);
        debugPrint('❌ Erro na conexão Realtime: $status');
        _scheduleReconnection(duelId);
        break;

      case RealtimeSubscribeStatus.closed:
        _connectivityController.add(false);
        debugPrint('🔌 Conexão Realtime fechada');
        break;
    }
  }

  void _handleRealtimeUpdate(Future<void> Function() updateFunction) async {
    try {
      await updateFunction();
    } catch (e) {
      debugPrint('Erro ao processar atualização Realtime: $e');
      // Não reconectar aqui, apenas logar o erro
    }
  }

  void _scheduleReconnection(String duelId) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Máximo de tentativas de reconexão atingido');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts; // Backoff exponencial

    debugPrint(
        '🔄 Tentativa de reconexão $_reconnectAttempts/$_maxReconnectAttempts em ${delay}ms...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (currentDuelId == duelId) {
        _reconnectToRealtime(duelId);
      }
    });
  }

  void _reconnectToRealtime(String duelId) {
    try {
      // Fechar conexão anterior se existir
      if (_duelChannel != null) {
        _supabase.removeChannel(_duelChannel!);
        _duelChannel = null;
      }

      // Estabelecer nova conexão
      _setupRealtimeConnection(duelId);
    } catch (e) {
      debugPrint('Erro na reconexão: $e');
      _scheduleReconnection(duelId);
    }
  }
  // ===================== FIM DO SISTEMA DE RECONEXÃO ======================

  Future<void> _fetchDuelAndParticipants(String duelId) async {
    final result = await DatabaseErrorHandler.execute<void>(
      () async {
        final duelData =
            await _supabase.from('duels').select().eq('id', duelId).single();
        if (!_duelController.isClosed) {
          _duelController.add(Duel.fromJson(duelData));
        }

        final participantsData = await _supabase
            .from('duel_participants')
            .select('*, profiles(username, avatar_url)')
            .eq('duel_id', duelId);
        final participants = participantsData
            .map<DuelParticipant>((p) => DuelParticipant.fromJson(p))
            .toList();
        if (!_participantsController.isClosed) {
          _participantsController.add(participants);
        }
      },
      operationName: '_fetchDuelAndParticipants',
      context: {'duelId': duelId},
    );

    if (result.isFailure) {
      debugPrint('❌ Erro ao buscar dados do duelo: ${result.errorMessage}');
      // Tentar reconexão se for erro de rede
      if (result.errorMessage?.contains('network') == true) {
        _scheduleReconnection(duelId);
      }
    }
  }

  Future<void> _fetchQuestions(String duelId) async {
    final result = await DatabaseErrorHandler.execute<void>(
      () async {
        final questionsData = await _supabase
            .from('duel_questions')
            .select()
            .eq('duel_id', duelId);
        final questions = questionsData
            .map<DuelQuestion>((q) => DuelQuestion.fromJson(q))
            .toList();
        if (!_questionsController.isClosed) {
          _questionsController.add(questions);
        }
      },
      operationName: '_fetchQuestions',
      context: {'duelId': duelId},
    );

    if (result.isFailure) {
      debugPrint('❌ Erro ao buscar perguntas do duelo: ${result.errorMessage}');
    }
  }

  Future<void> cancelSearch() async {
    if (currentDuelId != null) {
      await _supabase.from('duels').delete().eq('id', currentDuelId!);
    }
    dispose();
  }

  void dispose() {
    try {
      // Cancelar timer de reconexão
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Fechar canal Realtime
      if (_duelChannel != null) {
        _supabase.removeChannel(_duelChannel!);
        _duelChannel = null;
      }

      // Fechar controllers
      if (!_duelController.isClosed) {
        _duelController.close();
      }
      if (!_participantsController.isClosed) {
        _participantsController.close();
      }
      if (!_questionsController.isClosed) {
        _questionsController.close();
      }
      if (!_connectivityController.isClosed) {
        _connectivityController.close();
      }

      // Reset do estado
      _reconnectAttempts = 0;
      currentDuelId = null;

      debugPrint('DuelService disposed successfully');
    } catch (e) {
      debugPrint('Erro ao fazer dispose do DuelService: $e');
    }
  }
}
