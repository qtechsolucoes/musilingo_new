// lib/app/services/gamification_service.dart

import 'package:flutter/foundation.dart';
import 'package:musilingo/app/models/user_progress_model.dart';
import 'package:musilingo/app/core/service_registry.dart';

class GamificationService extends ChangeNotifier implements Disposable {
  // CORREÇÃO: Removido padrão Singleton, agora usa ServiceRegistry

  final UserProgress _userProgress = UserProgress();

  UserProgress get userProgress => _userProgress;

  void addPoints(int points, {required String reason}) {
    _userProgress.totalPoints += points;
    _userProgress.updateLevel();
    if (kDebugMode) {
      print(
          'Ganhos +$points XP por: $reason. Total de XP: ${_userProgress.totalPoints}');
    }

    // Notifica os widgets que estão ouvindo sobre a mudança.
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🧹 GamificationService disposed');
    super.dispose();
  }

  /// Factory method para usar com ServiceRegistry
  static GamificationService create() => GamificationService();
}
