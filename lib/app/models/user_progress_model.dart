// lib/app/models/user_progress_model.dart

class UserProgress {
  int totalPoints;
  int level;
  // Futuramente, você pode adicionar:
  // List<String> unlockedAchievements;
  // int dailyStreak;

  UserProgress({
    this.totalPoints = 0,
    this.level = 1,
  });

  // Um método simples para calcular o nível com base nos pontos.
  void updateLevel() {
    // A cada 100 pontos, o usuário sobe de nível.
    level = (totalPoints / 100).floor() + 1;
  }
}
