// lib/app/controllers/agent_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/models/agent_response_model.dart';
import 'package:musilingo/app/models/chat_message_model.dart';
import 'package:musilingo/app/models/game_action_model.dart';
import 'package:musilingo/app/services/ai_service.dart';

// Enum para os possíveis estados da CecilIA.
enum AgentState { neutro, feliz, pensando, explicando, triste }

class AgentController extends StateNotifier<AgentState> {
  final AIService _aiService;
  late final String _agentUrl;

  AgentController(this._aiService) : super(AgentState.explicando) {
    _agentUrl = const String.fromEnvironment('AI_AGENT_URL',
        defaultValue: 'https://f91beac9eba2.ngrok-free.app');
  }

  String get currentSvgUrl =>
      "$_agentUrl/agent_reaction?state=${state.name}";

  void changeState(AgentState newState) {
    if (state != newState) {
      state = newState;
    }
  }
  // --- Fim da Parte Visual ---

  // --- Lógica de Chat ---
  Future<String> startChat(List<ChatMessage> history) async {
    changeState(AgentState.pensando);
    try {
      final result = await _aiService.startChat(history);
      changeState(AgentState.explicando);
      return switch (result) {
        Success<String>(data: final data) => data,
        Failure<String>(errorMessage: final error) => throw Exception(error),
      };
    } catch (e) {
      changeState(AgentState.triste);
      rethrow;
    }
  }

  AgentResponse processFullResponse(String fullResponse) {
    final messageParts = fullResponse.split('---');
    final message = messageParts.first.trim();
    final actions = <GameAction>[];

    if (messageParts.length > 1) {
      final actionsString = messageParts.sublist(1).join('---');
      final actionRegex = RegExp(r'ACTION: (\w+)\((.*?)\)');
      final matches = actionRegex.allMatches(actionsString);

      for (final match in matches) {
        final type = match.group(1);
        final paramsString = match.group(2);
        final params = _parseParams(paramsString!);

        switch (type) {
          case 'ADD_POINTS':
            int pointsValue = 0;
            try {
              pointsValue = int.parse(params['points'] ?? '0');
            } catch (e) {
              pointsValue = 0;
            }
            actions.add(AddPointsAction(
              points: pointsValue,
              reason: params['reason'] ?? 'Ação da IA',
            ));
            break;

          case 'SHOW_CHALLENGE':
            actions.add(ShowChallengeAction(
              topic: params['topic'] ?? 'Desafio Geral',
            ));
            break;

          case 'START_PRACTICE':
            actions.add(StartPracticeAction(
              topic: params['topic'] ?? 'Prática Livre',
              difficulty: params['difficulty'] ?? 'normal',
            ));
            break;
        }
      }
    }
    return AgentResponse(message: message, actions: actions);
  }

  Map<String, String> _parseParams(String paramsString) {
    final params = <String, String>{};
    final pairs = paramsString.split(',');
    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim().replaceAll("'", "").replaceAll('"', '');
        final value =
            keyValue[1].trim().replaceAll("'", "").replaceAll('"', '');
        params[key] = value;
      }
    }
    return params;
  }
  // --- Fim da Lógica de Chat ---
}

// Provider para o AgentController
final agentControllerProvider = StateNotifierProvider<AgentController, AgentState>((ref) {
  final aiService = AIService(); // ou busque via ServiceRegistry se necessário
  return AgentController(aiService);
});
