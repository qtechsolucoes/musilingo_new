// lib/features/duel/data/models/duel_models.dart

enum DuelStatus { searching, ongoing, finished }

class Duel {
  final String id;
  final DuelStatus status;
  final String? winnerId;
  final DateTime createdAt;

  Duel({
    required this.id,
    required this.status,
    this.winnerId,
    required this.createdAt,
  });

  factory Duel.fromJson(Map<String, dynamic> json) {
    return Duel(
      id: json['id'],
      status: DuelStatus.values.firstWhere(
        (e) => e.toString() == 'DuelStatus.${json['status']}',
        orElse: () => DuelStatus.searching,
      ),
      winnerId: json['winner_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DuelParticipant {
  final String id;
  final String duelId;
  final String userId;
  final int score;
  final DateTime joinedAt;
  final String? username;
  final String? avatarUrl;

  DuelParticipant({
    required this.id,
    required this.duelId,
    required this.userId,
    required this.score,
    required this.joinedAt,
    this.username,
    this.avatarUrl,
  });

  factory DuelParticipant.fromJson(Map<String, dynamic> json) {
    return DuelParticipant(
      id: json['id'],
      duelId: json['duel_id'],
      userId: json['user_id'],
      score: json['score'],
      joinedAt: DateTime.parse(json['joined_at']),
      username: json['profiles'] != null ? json['profiles']['username'] : null,
      avatarUrl:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }
}

class DuelQuestion {
  final String id;
  final String duelId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? answeredByUserId;
  final DateTime? answeredAt;
  final DateTime createdAt;

  DuelQuestion({
    required this.id,
    required this.duelId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.answeredByUserId,
    this.answeredAt,
    required this.createdAt,
  });

  factory DuelQuestion.fromJson(Map<String, dynamic> json) {
    return DuelQuestion(
      id: json['id'],
      duelId: json['duel_id'],
      questionText: json['question_text'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correct_answer'],
      answeredByUserId: json['answered_by_user_id'],
      answeredAt: json['answered_at'] != null
          ? DateTime.parse(json['answered_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
