// ==========================================
// lib/features/practice_solfege/data/services/solfege_service.dart
// ==========================================
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_progress_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Import para debugPrint

class SolfegeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Helper para converter ID de forma segura (string ou int) para BigInt
  static BigInt _safeIdToBigInt(dynamic id) {
    if (id is String) {
      return BigInt.parse(id);
    } else if (id is int) {
      return BigInt.from(id);
    } else if (id is BigInt) {
      return id;
    } else {
      throw ArgumentError(
          'ID deve ser String, int ou BigInt, recebido: ${id.runtimeType}');
    }
  }

  Future<List<SolfegeExercise>> getSolfegeExercises() async {
    try {
      final response = await _supabase.from('practice_solfege').select();
      return (response as List)
          .map((e) => SolfegeExercise.fromJson(e))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar exercícios de solfejo: $e');
      }
      return [];
    }
  }

  Future<List<SolfegeExercise>> getExercisesByDifficulty(
      String difficulty) async {
    try {
      final response = await _supabase
          .from('practice_solfege')
          .select()
          .eq('difficulty_level', difficulty.toLowerCase());
      return (response as List)
          .map((e) => SolfegeExercise.fromJson(e))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar exercícios por dificuldade: $e');
      }
      return [];
    }
  }

  Future<SolfegeExercise?> getExerciseById(String id) async {
    try {
      final intId = int.tryParse(id);
      if (intId == null) return null;

      final response = await _supabase
          .from('practice_solfege')
          .select()
          .eq('id', intId)
          .single();
      return SolfegeExercise.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar exercício por ID: $e');
      }
      return null;
    }
  }

  // ==========================================
  // MÉTODOS DE PROGRESSO
  // ==========================================

  /// Salva ou atualiza o progresso de um exercício
  Future<void> saveExerciseProgress({
    required String userId,
    required BigInt exerciseId,
    required int score,
  }) async {
    try {
      // CORREÇÃO: A consulta agora é feita na tabela 'solfege_progress'
      final existingProgress = await _supabase
          .from('solfege_progress') // <-- CORRIGIDO
          .select()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId.toInt())
          .maybeSingle();

      final now = DateTime.now().toIso8601String();

      if (existingProgress != null) {
        // Atualizar progresso existente
        final currentBestScore = existingProgress['best_score'] as int? ?? 0;
        final newBestScore =
            score > currentBestScore ? score : currentBestScore;
        final currentAttempts = existingProgress['attempts'] as int? ?? 0;

        await _supabase
            .from('solfege_progress')
            .update({
              'best_score': newBestScore,
              'attempts': currentAttempts + 1,
              'last_attempt_at': now,
              'first_completed_at': existingProgress['first_completed_at'] ??
                  (score >= 50 ? now : null),
            })
            .eq('user_id', userId)
            .eq('exercise_id', exerciseId.toInt());

        debugPrint(
            'Progresso atualizado - Exercício $exerciseId: $newBestScore%');
      } else {
        // Criar novo progresso
        await _supabase.from('solfege_progress').insert({
          'user_id': userId,
          'exercise_id': exerciseId.toInt(),
          'best_score': score,
          'attempts': 1,
          'is_unlocked': true,
          'first_completed_at': score >= 50 ? now : null,
          'last_attempt_at': now,
        });

        debugPrint('Novo progresso criado - Exercício $exerciseId: $score%');
      }

      // Se o score for >= 90%, desbloquear próximo exercício
      if (score >= 90) {
        await _unlockNextExercise(userId, exerciseId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao salvar progresso do exercício: $e');
      }
    }
  }

  /// Desbloqueia o próximo exercício baseado no ID atual
  Future<void> _unlockNextExercise(
      String userId, BigInt currentExerciseId) async {
    try {
      // Buscar o próximo exercício na mesma dificuldade
      final currentExercises = await _supabase
          .from('practice_solfege')
          .select()
          .eq('id', currentExerciseId.toInt());

      if (currentExercises.isEmpty) {
        debugPrint('Exercício atual não encontrado: $currentExerciseId');
        return;
      }

      final currentExercise = currentExercises.first;

      final nextExercises = await _supabase
          .from('practice_solfege')
          .select()
          .eq('difficulty_level', currentExercise['difficulty_level'])
          .gt('difficulty_value', currentExercise['difficulty_value'])
          .order('difficulty_value')
          .limit(1);

      final nextExercise =
          nextExercises.isNotEmpty ? nextExercises.first : null;

      if (nextExercise != null) {
        final nextExerciseId = _safeIdToBigInt(nextExercise['id']);

        // Verificar se já existe progresso para o próximo exercício
        final existingProgressList = await _supabase
            .from('solfege_progress')
            .select()
            .eq('user_id', userId)
            .eq('exercise_id', nextExerciseId.toInt());

        final existingProgress =
            existingProgressList.isNotEmpty ? existingProgressList.first : null;

        if (existingProgress == null) {
          // Criar progresso desbloqueado para o próximo exercício
          await _supabase.from('solfege_progress').insert({
            'user_id': userId,
            'exercise_id': nextExerciseId.toInt(),
            'best_score': 0,
            'attempts': 0,
            'is_unlocked': true,
            'first_completed_at': null,
            'last_attempt_at': null,
          });

          debugPrint('Próximo exercício desbloqueado: $nextExerciseId');
        } else if (!(existingProgress['is_unlocked'] as bool? ?? false)) {
          // Desbloquear exercício existente
          await _supabase
              .from('solfege_progress')
              .update({'is_unlocked': true})
              .eq('user_id', userId)
              .eq('exercise_id', nextExerciseId.toInt());

          debugPrint('Exercício $nextExerciseId desbloqueado');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao desbloquear próximo exercício: $e');
      }
    }
  }

  /// Busca o progresso do usuário para um exercício específico
  Future<SolfegeProgress?> getUserProgress(
      String userId, BigInt exerciseId) async {
    try {
      final response = await _supabase
          .from('solfege_progress')
          .select()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId.toInt());

      if (response.isEmpty) {
        return null;
      }

      return SolfegeProgress.fromMap(response.first);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar progresso do usuário: $e');
      }
      return null;
    }
  }

  /// Busca todos os progressos do usuário para uma dificuldade
  Future<List<SolfegeProgress>> getUserProgressByDifficulty(
      String userId, String difficulty) async {
    try {
      final response = await _supabase
          .from('solfege_progress')
          .select('*, practice_solfege!fk_exercise(*)')
          .eq('user_id', userId)
          .eq('practice_solfege.difficulty_level', difficulty.toLowerCase());

      return (response as List).map((e) => SolfegeProgress.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar progresso por dificuldade: $e');
      }
      return [];
    }
  }

  /// Inicializa o progresso para um usuário (desbloqueia o primeiro exercício)
  Future<void> initializeUserProgress(String userId, String difficulty) async {
    try {
      // Buscar o primeiro exercício da dificuldade
      final firstExercises = await _supabase
          .from('practice_solfege')
          .select()
          .eq('difficulty_level', difficulty.toLowerCase())
          .order('difficulty_value')
          .limit(1);

      if (firstExercises.isEmpty) {
        debugPrint(
            'Nenhum exercício encontrado para a dificuldade: $difficulty');
        return;
      }

      final firstExercise = firstExercises.first;

      final exerciseId = _safeIdToBigInt(firstExercise['id']);

      // Verificar se já existe progresso
      final existingProgress = await getUserProgress(userId, exerciseId);

      if (existingProgress == null) {
        await _supabase.from('solfege_progress').insert({
          'user_id': userId,
          'exercise_id': exerciseId.toInt(),
          'best_score': 0,
          'attempts': 0,
          'is_unlocked': true,
          'first_completed_at': null,
          'last_attempt_at': null,
        });

        debugPrint(
            'Progresso inicializado - Primeiro exercício desbloqueado: $exerciseId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao inicializar progresso do usuário: $e');
      }
    }
  }
}
