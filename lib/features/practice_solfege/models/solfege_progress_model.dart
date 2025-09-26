// lib/features/practice_solfege/models/solfege_progress_model.dart

class SolfegeProgress {
  final String userId;
  final BigInt exerciseId;
  final int bestScore;
  final int attempts;
  final bool isUnlocked;
  final DateTime? firstCompletedAt;
  final DateTime? lastAttemptAt;

  SolfegeProgress({
    required this.userId,
    required this.exerciseId,
    this.bestScore = 0,
    this.attempts = 0,
    this.isUnlocked = false,
    this.firstCompletedAt,
    this.lastAttemptAt,
  });

  /// Helper para converter ID de forma segura (string ou int) para BigInt
  static BigInt _safeIdToBigInt(dynamic id) {
    if (id is String) {
      return BigInt.parse(id);
    } else if (id is int) {
      return BigInt.from(id);
    } else if (id is BigInt) {
      return id;
    } else {
      throw ArgumentError('ID deve ser String, int ou BigInt, recebido: ${id.runtimeType}');
    }
  }

  factory SolfegeProgress.fromMap(Map<String, dynamic> map) {
    return SolfegeProgress(
      userId: map['user_id'] as String,
      exerciseId: _safeIdToBigInt(map['exercise_id']),
      bestScore: map['best_score'] as int? ?? 0,
      attempts: map['attempts'] as int? ?? 0,
      isUnlocked: map['is_unlocked'] as bool? ?? false,
      firstCompletedAt: map['first_completed_at'] != null
          ? DateTime.parse(map['first_completed_at'] as String)
          : null,
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'exercise_id': exerciseId.toInt(),
      'best_score': bestScore,
      'attempts': attempts,
      'is_unlocked': isUnlocked,
      'first_completed_at': firstCompletedAt?.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
    };
  }

  SolfegeProgress copyWith({
    String? userId,
    BigInt? exerciseId,
    int? bestScore,
    int? attempts,
    bool? isUnlocked,
    DateTime? firstCompletedAt,
    DateTime? lastAttemptAt,
  }) {
    return SolfegeProgress(
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  /// Verifica se o exercício foi completado com sucesso (90% ou mais)
  bool get isCompleted => bestScore >= 90;

  /// Verifica se o usuário passou do mínimo (50% ou mais)
  bool get isPassed => bestScore >= 50;
}