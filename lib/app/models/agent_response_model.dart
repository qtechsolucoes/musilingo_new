import 'package:musilingo/app/models/game_action_model.dart';

/// Representa a resposta processada da IA, separando a mensagem de texto
/// das ações de gamificação que devem ser executadas.
class AgentResponse {
  final String message;
  final List<GameAction> actions;

  AgentResponse({
    required this.message,
    this.actions = const [],
  });
}
