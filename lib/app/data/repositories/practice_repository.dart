// lib/app/data/repositories/practice_repository.dart

import 'package:musilingo/app/core/repositories/base_repository.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/app/data/models/harmonic_exercise_model.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';
import 'package:musilingo/main.dart';

/// Repository para operações relacionadas a exercícios de prática
class PracticeRepository extends BaseRepository<dynamic, int> {
  // Cache para diferentes tipos de exercícios
  final _melodicCache = <int, MelodicExercise>{};
  final _harmonicCache = <int, HarmonicExercise>{};
  final _solfegeCache = <int, SolfegeExercise>{};

  /// Busca exercícios melódicos
  Future<Result<List<MelodicExercise>>> findMelodicExercises({
    String? clef,
    String? keySignature,
    String? difficulty,
  }) async {
    try {
      var query = supabase.from('practice_melodies').select();

      if (clef != null) query = query.eq('clef', clef);
      if (keySignature != null) query = query.eq('key_signature', keySignature);
      if (difficulty != null) query = query.eq('difficulty', difficulty);

      final response = await query.order('id');

      final exercises = response
          .map<MelodicExercise>((json) => MelodicExercise.fromMap(json))
          .toList();

      // Atualiza cache
      for (final exercise in exercises) {
        _melodicCache[exercise.id] = exercise;
      }

      return Success(exercises);
    } catch (error) {
      return Failure('Erro ao buscar exercícios melódicos: $error');
    }
  }

  /// Busca exercícios harmônicos
  Future<Result<List<HarmonicExercise>>> findHarmonicExercises({
    String? chordType,
    String? inversion,
    String? difficulty,
  }) async {
    try {
      var query = supabase.from('practice_harmonies').select();

      if (chordType != null) query = query.eq('chord_type', chordType);
      if (inversion != null) query = query.eq('inversion', inversion);
      if (difficulty != null) query = query.eq('difficulty', difficulty);

      final response = await query.order('id');

      final exercises = response
          .map<HarmonicExercise>((json) => HarmonicExercise.fromMap(json))
          .toList();

      // Atualiza cache
      for (final exercise in exercises) {
        _harmonicCache[exercise.id] = exercise;
      }

      return Success(exercises);
    } catch (error) {
      return Failure('Erro ao buscar exercícios harmônicos: $error');
    }
  }

  /// Busca exercícios de solfejo
  Future<Result<List<SolfegeExercise>>> findSolfegeExercises({
    String? difficulty,
    String? keySignature,
    String? clef,
  }) async {
    try {
      var query = supabase.from('practice_solfege').select();

      if (difficulty != null) query = query.eq('difficulty_level', difficulty);
      if (keySignature != null) query = query.eq('key_signature', keySignature);
      if (clef != null) query = query.eq('clef', clef);

      final response = await query.order('difficulty_value');

      final exercises = response
          .map<SolfegeExercise>((json) => SolfegeExercise.fromMap(json))
          .toList();

      return Success(exercises);
    } catch (error) {
      return Failure('Erro ao buscar exercícios de solfejo: $error');
    }
  }

  /// Busca exercício melódico por ID
  Future<Result<MelodicExercise?>> findMelodicById(int id) async {
    try {
      if (_melodicCache.containsKey(id)) {
        return Success(_melodicCache[id]);
      }

      final response = await supabase
          .from('practice_melodies')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final exercise = MelodicExercise.fromMap(response);
      _melodicCache[id] = exercise;

      return Success(exercise);
    } catch (error) {
      return Failure('Erro ao buscar exercício melódico: $error');
    }
  }

  /// Busca exercício harmônico por ID
  Future<Result<HarmonicExercise?>> findHarmonicById(int id) async {
    try {
      if (_harmonicCache.containsKey(id)) {
        return Success(_harmonicCache[id]);
      }

      final response = await supabase
          .from('practice_harmonies')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final exercise = HarmonicExercise.fromMap(response);
      _harmonicCache[id] = exercise;

      return Success(exercise);
    } catch (error) {
      return Failure('Erro ao buscar exercício harmônico: $error');
    }
  }

  /// Registra resultado de exercício
  Future<Result<bool>> recordExerciseResult({
    required String userId,
    required String exerciseType,
    required int exerciseId,
    required bool isCorrect,
    required int score,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final recordData = {
        'user_id': userId,
        'exercise_type': exerciseType,
        'exercise_id': exerciseId,
        'is_correct': isCorrect,
        'score': score,
        'completed_at': DateTime.now().toIso8601String(),
        'additional_data': additionalData,
      };

      await supabase.from('practice_results').insert(recordData);

      return const Success(true);
    } catch (error) {
      return Failure('Erro ao registrar resultado: $error');
    }
  }

  /// Busca histórico de resultados do usuário
  Future<Result<List<Map<String, dynamic>>>> findUserResults(
    String userId, {
    String? exerciseType,
    int? limit = 50,
  }) async {
    try {
      var query =
          supabase.from('practice_results').select().eq('user_id', userId);

      if (exerciseType != null) {
        query = query.eq('exercise_type', exerciseType);
      }

      final response =
          await query.order('completed_at', ascending: false).limit(limit!);

      return Success(List<Map<String, dynamic>>.from(response));
    } catch (error) {
      return Failure('Erro ao buscar resultados: $error');
    }
  }

  /// Busca estatísticas de performance do usuário
  Future<Result<Map<String, dynamic>>> findUserStats(String userId) async {
    try {
      final response = await supabase
          .rpc('get_user_practice_stats', params: {'user_id_param': userId});

      return Success(Map<String, dynamic>.from(response));
    } catch (error) {
      return Failure('Erro ao buscar estatísticas: $error');
    }
  }

  /// Busca exercícios recomendados baseado na performance
  Future<Result<Map<String, List<dynamic>>>> findRecommendedExercises(
    String userId,
  ) async {
    try {
      // Busca estatísticas do usuário para fazer recomendações
      final statsResult = await findUserStats(userId);
      if (statsResult.isFailure) {
        // Se falhar, retorna exercícios básicos
        return _getBasicRecommendations();
      }

      final stats = statsResult.data;
      final averageScore = stats['average_score'] ?? 70;

      // Determina dificuldade baseada na performance
      String difficulty;
      if (averageScore >= 85) {
        difficulty = 'hard';
      } else if (averageScore >= 70) {
        difficulty = 'medium';
      } else {
        difficulty = 'easy';
      }

      final melodicResult = await findMelodicExercises(difficulty: difficulty);
      final harmonicResult =
          await findHarmonicExercises(difficulty: difficulty);
      final solfegeResult = await findSolfegeExercises(difficulty: difficulty);

      return Success({
        'melodic': melodicResult.isSuccess ? melodicResult.data : <dynamic>[],
        'harmonic':
            harmonicResult.isSuccess ? harmonicResult.data : <dynamic>[],
        'solfege': solfegeResult.isSuccess ? solfegeResult.data : <dynamic>[],
      });
    } catch (error) {
      return Failure('Erro ao buscar recomendações: $error');
    }
  }

  /// Limpa todos os caches
  Future<void> clearAllCaches() async {
    _melodicCache.clear();
    _harmonicCache.clear();
    _solfegeCache.clear();
  }

  /// Retorna recomendações básicas para novos usuários
  Future<Result<Map<String, List<dynamic>>>> _getBasicRecommendations() async {
    final melodicResult = await findMelodicExercises(difficulty: 'easy');
    final harmonicResult = await findHarmonicExercises(difficulty: 'easy');
    final solfegeResult = await findSolfegeExercises(difficulty: 'easy');

    return Success({
      'melodic': melodicResult.isSuccess ? melodicResult.data : <dynamic>[],
      'harmonic': harmonicResult.isSuccess ? harmonicResult.data : <dynamic>[],
      'solfege': solfegeResult.isSuccess ? solfegeResult.data : <dynamic>[],
    });
  }

  // Implementações obrigatórias da BaseRepository
  @override
  Future<Result<dynamic>> findById(int id) async {
    return const Failure('Use métodos específicos por tipo de exercício');
  }

  @override
  Future<Result<List<dynamic>>> findAll() async {
    return const Failure('Use métodos específicos por tipo de exercício');
  }

  @override
  Future<Result<dynamic>> create(dynamic item) async {
    return const Failure('Criação de exercícios não implementada');
  }

  @override
  Future<Result<dynamic>> update(int id, dynamic item) async {
    return const Failure('Atualização de exercícios não implementada');
  }

  @override
  Future<Result<bool>> delete(int id) async {
    return const Failure('Deleção de exercícios não implementada');
  }

  @override
  Future<Result<List<dynamic>>> findWithPagination({
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? filters,
  }) async {
    return const Failure('Use métodos específicos por tipo de exercício');
  }

  @override
  Future<Result<int>> count() async {
    return const Failure('Use métodos específicos por tipo de exercício');
  }
}
