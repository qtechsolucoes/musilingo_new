// lib/app/data/models/user_profile_model.dart

class UserProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final int points;
  final int lives;
  final int correctAnswers;
  final int wrongAnswers;
  final int currentStreak;
  final String? lastPracticeDate;
  final String league;
  final int roleId;
  // --- NOVAS ADIÇÕES ---
  final String? description;
  final String? specialty;
  // --- FIM DAS ADIÇÕES ---

  UserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.points = 0,
    this.lives = 5,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.currentStreak = 0,
    this.lastPracticeDate,
    required this.league,
    this.roleId = 1,
    // Adicionados ao construtor
    this.description,
    this.specialty,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      points: map['points'] as int? ?? 0,
      lives: map['lives'] as int? ?? 5,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      wrongAnswers: map['wrong_answers'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
      lastPracticeDate: map['last_practice_date'] as String?,
      league: map['league'] as String? ?? 'Bronze',
      roleId: map['role_id'] as int? ?? 1,
      // Lendo os novos campos da base de dados
      description: map['description'] as String?,
      specialty: map['specialty'] as String?,
    );
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    int? points,
    int? lives,
    int? correctAnswers,
    int? wrongAnswers,
    int? currentStreak,
    String? lastPracticeDate,
    String? league,
    int? roleId,
    String? description,
    String? specialty,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      lives: lives ?? this.lives,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      league: league ?? this.league,
      roleId: roleId ?? this.roleId,
      description: description ?? this.description,
      specialty: specialty ?? this.specialty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'points': points,
      'lives': lives,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
      'current_streak': currentStreak,
      'last_practice_date': lastPracticeDate,
      'league': league,
      'role_id': roleId,
      'description': description,
      'specialty': specialty,
    };
  }
}
