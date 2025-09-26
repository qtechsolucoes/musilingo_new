// lib/app/models/game_action_model.dart

abstract class GameAction {
  final String type;
  GameAction(this.type);
}

class AddPointsAction extends GameAction {
  // CORREÇÃO CRÍTICA: Garanta que 'points' seja do tipo 'int'.
  final int points;
  final String reason;

  AddPointsAction({required this.points, required this.reason})
      : super('ADD_POINTS');
}

class ShowChallengeAction extends GameAction {
  final String topic;

  ShowChallengeAction({required this.topic}) : super('SHOW_CHALLENGE');
}

class StartPracticeAction extends GameAction {
  final String topic;
  final String difficulty;

  StartPracticeAction({required this.topic, required this.difficulty})
      : super('START_PRACTICE');
}
