// lib/features/practice_solfege/data/services/solfege_database_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/data/models/solfege_progress.dart';

class SolfegeDatabaseService {
  static SolfegeDatabaseService? _instance;
  static SolfegeDatabaseService get instance => _instance ??= SolfegeDatabaseService._();

  SolfegeDatabaseService._();

  final _supabase = Supabase.instance.client;

  // Cache dos exercícios para evitar queries repetidas
  final Map<String, List<SolfegeExercise>> _exercisesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const cacheTimeout = Duration(minutes: 10);

  /// Carregar exercícios por nível de dificuldade
  Future<List<SolfegeExercise>> getExercisesByLevel(String level) async {
    try {
      // Verificar cache
      final cacheKey = 'exercises_$level';
      final cachedTimestamp = _cacheTimestamps[cacheKey];
      final now = DateTime.now();

      if (cachedTimestamp != null &&
          now.difference(cachedTimestamp) < cacheTimeout &&
          _exercisesCache.containsKey(cacheKey)) {
        debugPrint('🎵 Usando cache para exercícios de solfejo nível: $level');
        return _exercisesCache[cacheKey]!;
      }

      debugPrint('🎵 Carregando exercícios de solfejo do Supabase - nível: $level');

      final response = await _supabase
          .from('practice_solfege')
          .select()
          .eq('difficulty_level', level)
          .order('difficulty_value', ascending: true);

      final exercises = (response as List<dynamic>)
          .map((json) => SolfegeExercise.fromJson(json))
          .toList();

      // Salvar no cache
      _exercisesCache[cacheKey] = exercises;
      _cacheTimestamps[cacheKey] = now;

      debugPrint('🎵 Carregados ${exercises.length} exercícios de solfejo');
      return exercises;

    } catch (e) {
      debugPrint('❌ Erro ao carregar exercícios de solfejo: $e');
      rethrow;
    }
  }

  /// Carregar exercício específico por ID
  Future<SolfegeExercise?> getExerciseById(int exerciseId) async {
    try {
      debugPrint('🎵 Carregando exercício de solfejo ID: $exerciseId');

      final response = await _supabase
          .from('practice_solfege')
          .select()
          .eq('id', exerciseId)
          .single();

      return SolfegeExercise.fromJson(response);

    } catch (e) {
      debugPrint('❌ Erro ao carregar exercício $exerciseId: $e');
      return null;
    }
  }

  /// Carregar progresso do usuário para um exercício específico
  Future<SolfegeProgress?> getUserProgress(String userId, int exerciseId) async {
    try {
      debugPrint('🎵 Carregando progresso do usuário $userId para exercício $exerciseId');

      final response = await _supabase
          .from('solfege_progress')
          .select()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .maybeSingle();

      if (response == null) {
        debugPrint('🎵 Nenhum progresso encontrado para exercício $exerciseId');
        return null;
      }

      return SolfegeProgress.fromJson(response);

    } catch (e) {
      debugPrint('❌ Erro ao carregar progresso: $e');
      return null;
    }
  }

  /// Carregar todo o progresso do usuário
  Future<List<SolfegeProgress>> getAllUserProgress(String userId) async {
    try {
      debugPrint('🎵 Carregando todo progresso do usuário $userId');

      final response = await _supabase
          .from('solfege_progress')
          .select()
          .eq('user_id', userId)
          .order('exercise_id', ascending: true);

      return (response as List<dynamic>)
          .map((json) => SolfegeProgress.fromJson(json))
          .toList();

    } catch (e) {
      debugPrint('❌ Erro ao carregar progresso completo: $e');
      return [];
    }
  }

  /// Verificar quais exercícios estão desbloqueados para o usuário
  Future<List<int>> getUnlockedExercises(String userId, String level) async {
    try {
      debugPrint('🎵 Verificando exercícios desbloqueados para usuário $userId, nível $level');

      // Primeiro, pegar todos os exercícios do nível
      final exercises = await getExercisesByLevel(level);
      if (exercises.isEmpty) return [];

      // Se não há progresso, apenas o primeiro exercício está desbloqueado
      final progress = await getAllUserProgress(userId);
      if (progress.isEmpty) {
        // Desbloquear automaticamente o primeiro exercício
        final firstExerciseId = int.parse(exercises.first.id);
        await _unlockFirstExercise(userId, firstExerciseId);
        return [firstExerciseId];
      }

      // Mapear exercícios desbloqueados
      final unlockedIds = progress
          .where((p) => p.isUnlocked)
          .map((p) => p.exerciseId)
          .toList();

      debugPrint('🎵 Exercícios desbloqueados: $unlockedIds');
      return unlockedIds;

    } catch (e) {
      debugPrint('❌ Erro ao verificar desbloqueios: $e');
      return [];
    }
  }

  /// Salvar resultado de um exercício
  Future<SolfegeProgress> saveExerciseResult(String userId, int exerciseId, int score) async {
    try {
      debugPrint('🎵 Salvando resultado: usuário $userId, exercício $exerciseId, score $score');

      final now = DateTime.now();

      // Verificar se já existe progresso
      final existingProgress = await getUserProgress(userId, exerciseId);

      if (existingProgress != null) {
        // Atualizar progresso existente
        final newBestScore = score > existingProgress.bestScore ? score : existingProgress.bestScore;
        final isFirstCompletion = existingProgress.firstCompletedAt == null && score >= 90;

        final response = await _supabase
            .from('solfege_progress')
            .update({
              'best_score': newBestScore,
              'attempts': existingProgress.attempts + 1,
              'last_attempt_at': now.toIso8601String(),
              'first_completed_at': isFirstCompletion ? now.toIso8601String() : existingProgress.firstCompletedAt?.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('id', existingProgress.id)
            .select()
            .single();

        final updatedProgress = SolfegeProgress.fromJson(response);

        // Se atingiu 90% ou mais, desbloquear próximo exercício
        if (score >= 90) {
          await _unlockNextExercise(userId, exerciseId);
        }

        return updatedProgress;

      } else {
        // Criar novo progresso
        final response = await _supabase
            .from('solfege_progress')
            .insert({
              'user_id': userId,
              'exercise_id': exerciseId,
              'best_score': score,
              'attempts': 1,
              'is_unlocked': true,
              'first_completed_at': score >= 90 ? now.toIso8601String() : null,
              'last_attempt_at': now.toIso8601String(),
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .select()
            .single();

        final newProgress = SolfegeProgress.fromJson(response);

        // Se atingiu 90% ou mais, desbloquear próximo exercício
        if (score >= 90) {
          await _unlockNextExercise(userId, exerciseId);
        }

        return newProgress;
      }

    } catch (e) {
      debugPrint('❌ Erro ao salvar resultado: $e');
      rethrow;
    }
  }

  /// Desbloquear automaticamente o primeiro exercício para novos usuários
  Future<void> _unlockFirstExercise(String userId, int firstExerciseId) async {
    try {
      await _supabase.from('solfege_progress').insert({
        'user_id': userId,
        'exercise_id': firstExerciseId,
        'best_score': 0,
        'attempts': 0,
        'is_unlocked': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('🎵 Primeiro exercício $firstExerciseId desbloqueado para usuário $userId');
    } catch (e) {
      debugPrint('❌ Erro ao desbloquear primeiro exercício: $e');
    }
  }

  /// Desbloquear próximo exercício na sequência
  Future<void> _unlockNextExercise(String userId, int completedExerciseId) async {
    try {
      // Encontrar o exercício atual e determinar o próximo
      final exercises = await getExercisesByLevel('iniciante'); // Por enquanto só temos iniciante
      final currentIndex = exercises.indexWhere((e) => e.id == completedExerciseId.toString());

      if (currentIndex == -1 || currentIndex >= exercises.length - 1) {
        debugPrint('🎵 Não há próximo exercício para desbloquear');
        return;
      }

      final nextExercise = exercises[currentIndex + 1];
      final nextExerciseId = int.parse(nextExercise.id);

      // Verificar se o próximo já está desbloqueado
      final existingProgress = await getUserProgress(userId, nextExerciseId);
      if (existingProgress?.isUnlocked == true) {
        debugPrint('🎵 Próximo exercício já está desbloqueado');
        return;
      }

      // Desbloquear próximo exercício
      if (existingProgress != null) {
        await _supabase
            .from('solfege_progress')
            .update({
              'is_unlocked': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingProgress.id);
      } else {
        await _supabase.from('solfege_progress').insert({
          'user_id': userId,
          'exercise_id': nextExerciseId,
          'best_score': 0,
          'attempts': 0,
          'is_unlocked': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('🎵 Próximo exercício $nextExerciseId desbloqueado para usuário $userId');

    } catch (e) {
      debugPrint('❌ Erro ao desbloquear próximo exercício: $e');
    }
  }

  /// Limpar cache (útil para testes ou atualizações forçadas)
  void clearCache() {
    _exercisesCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🎵 Cache de exercícios limpo');
  }
}