// lib/features/practice_solfege/providers/solfege_exercises_list_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/app/core/service_registry.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/data/models/solfege_progress.dart';
import 'package:musilingo/features/practice_solfege/data/services/solfege_database_service.dart';

// Estado da lista de exercícios
class SolfegeExercisesListState {
  final List<SolfegeExercise> exercises;
  final List<SolfegeProgress> userProgress;
  final List<int> unlockedExerciseIds;
  final bool isLoading;
  final String? error;
  final String selectedLevel;

  const SolfegeExercisesListState({
    this.exercises = const [],
    this.userProgress = const [],
    this.unlockedExerciseIds = const [],
    this.isLoading = false,
    this.error,
    this.selectedLevel = 'iniciante',
  });

  SolfegeExercisesListState copyWith({
    List<SolfegeExercise>? exercises,
    List<SolfegeProgress>? userProgress,
    List<int>? unlockedExerciseIds,
    bool? isLoading,
    String? error,
    String? selectedLevel,
  }) {
    return SolfegeExercisesListState(
      exercises: exercises ?? this.exercises,
      userProgress: userProgress ?? this.userProgress,
      unlockedExerciseIds: unlockedExerciseIds ?? this.unlockedExerciseIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedLevel: selectedLevel ?? this.selectedLevel,
    );
  }

  // Métodos de conveniência
  bool isExerciseUnlocked(int exerciseId) {
    return unlockedExerciseIds.contains(exerciseId);
  }

  SolfegeProgress? getProgressForExercise(int exerciseId) {
    try {
      return userProgress.firstWhere((p) => p.exerciseId == exerciseId);
    } catch (e) {
      return null;
    }
  }

  bool isExerciseCompleted(int exerciseId) {
    final progress = getProgressForExercise(exerciseId);
    return progress?.isCompleted ?? false;
  }

  int getExerciseBestScore(int exerciseId) {
    final progress = getProgressForExercise(exerciseId);
    return progress?.bestScore ?? 0;
  }
}

// Notifier para gerenciar a lista de exercícios
class SolfegeExercisesListNotifier extends StateNotifier<SolfegeExercisesListState> {
  final SolfegeDatabaseService _databaseService = SolfegeDatabaseService.instance;

  SolfegeExercisesListNotifier() : super(const SolfegeExercisesListState());

  // Carregar exercícios e progresso do usuário
  Future<void> loadExercisesAndProgress({String level = 'iniciante'}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Obter userId do UserSession
      final userSession = ServiceRegistry.get<UserSession>();
      final userId = userSession.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuário não está logado');
      }

      debugPrint('🎵 Carregando exercícios de solfejo para nível: $level');

      // Carregar exercícios do nível
      final exercises = await _databaseService.getExercisesByLevel(level);

      // Carregar progresso do usuário
      final userProgress = await _databaseService.getAllUserProgress(userId);

      // Carregar IDs desbloqueados
      final unlockedIds = await _databaseService.getUnlockedExercises(userId, level);

      state = state.copyWith(
        exercises: exercises,
        userProgress: userProgress,
        unlockedExerciseIds: unlockedIds,
        isLoading: false,
        selectedLevel: level,
      );

      debugPrint('🎵 Carregados ${exercises.length} exercícios, ${unlockedIds.length} desbloqueados');

    } catch (e) {
      debugPrint('❌ Erro ao carregar exercícios: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Atualizar progresso de um exercício específico (chamado após completar)
  Future<void> updateExerciseProgress(int exerciseId, SolfegeProgress newProgress) async {
    try {
      final updatedProgress = state.userProgress.map((p) {
        if (p.exerciseId == exerciseId) {
          return newProgress;
        }
        return p;
      }).toList();

      // Se o progresso não existia antes, adicionar
      if (!updatedProgress.any((p) => p.exerciseId == exerciseId)) {
        updatedProgress.add(newProgress);
      }

      // Recarregar IDs desbloqueados se houve melhoria
      if (newProgress.bestScore >= 90) {
        final userSession = ServiceRegistry.get<UserSession>();
        final userId = userSession.currentUser?.id;

        if (userId != null) {
          final unlockedIds = await _databaseService.getUnlockedExercises(userId, state.selectedLevel);
          state = state.copyWith(
            userProgress: updatedProgress,
            unlockedExerciseIds: unlockedIds,
          );
        }
      } else {
        state = state.copyWith(userProgress: updatedProgress);
      }

      debugPrint('🎵 Progresso do exercício $exerciseId atualizado');

    } catch (e) {
      debugPrint('❌ Erro ao atualizar progresso: $e');
    }
  }

  // Recarregar dados (pull-to-refresh)
  Future<void> refresh() async {
    await loadExercisesAndProgress(level: state.selectedLevel);
  }

  // Alterar nível de dificuldade
  Future<void> changeLevel(String newLevel) async {
    if (newLevel != state.selectedLevel) {
      await loadExercisesAndProgress(level: newLevel);
    }
  }
}

// Provider para a lista de exercícios
final solfegeExercisesListProvider = StateNotifierProvider<SolfegeExercisesListNotifier, SolfegeExercisesListState>((ref) {
  return SolfegeExercisesListNotifier();
});