// lib/features/practice_solfege/data/models/solfege_progress.dart

class SolfegeProgress {
  final int id;
  final String userId;
  final int exerciseId;
  final int bestScore;
  final int attempts;
  final bool isUnlocked;
  final DateTime? firstCompletedAt;
  final DateTime? lastAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SolfegeProgress({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.bestScore,
    required this.attempts,
    required this.isUnlocked,
    this.firstCompletedAt,
    this.lastAttemptAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SolfegeProgress.fromJson(Map<String, dynamic> json) {
    return SolfegeProgress(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      exerciseId: json['exercise_id'] ?? 0,
      bestScore: json['best_score'] ?? 0,
      attempts: json['attempts'] ?? 0,
      isUnlocked: json['is_unlocked'] ?? false,
      firstCompletedAt: json['first_completed_at'] != null
          ? DateTime.parse(json['first_completed_at'])
          : null,
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'])
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_id': exerciseId,
      'best_score': bestScore,
      'attempts': attempts,
      'is_unlocked': isUnlocked,
      'first_completed_at': firstCompletedAt?.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SolfegeProgress copyWith({
    int? id,
    String? userId,
    int? exerciseId,
    int? bestScore,
    int? attempts,
    bool? isUnlocked,
    DateTime? firstCompletedAt,
    DateTime? lastAttemptAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SolfegeProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Métodos de conveniência
  bool get isCompleted => bestScore >= 90;
  bool get shouldLoseLife => bestScore > 0 && bestScore < 50;
  bool get hasAttempts => attempts > 0;

  @override
  String toString() {
    return 'SolfegeProgress(id: $id, exerciseId: $exerciseId, bestScore: $bestScore, attempts: $attempts, isUnlocked: $isUnlocked)';
  }
}

// Enum para facilitar o sistema de pontuação
enum SolfegeScoreResult {
  excellent, // >= 90% - desbloqueio + pontos
  good,      // 50-89% - sem penalidade
  poor,      // < 50% - perde vida
}

extension SolfegeScoreResultExtension on SolfegeScoreResult {
  static SolfegeScoreResult fromScore(int score) {
    if (score >= 90) return SolfegeScoreResult.excellent;
    if (score >= 50) return SolfegeScoreResult.good;
    return SolfegeScoreResult.poor;
  }

  bool get shouldUnlockNext => this == SolfegeScoreResult.excellent;
  bool get shouldLoseLife => this == SolfegeScoreResult.poor;
  bool get shouldGainPoints => this == SolfegeScoreResult.excellent;
}