// lib/app/services/database_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/core/database_error_handler.dart';
import 'package:musilingo/app/data/models/harmonic_exercise_model.dart';
import 'package:musilingo/app/data/models/harmonic_progression_model.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/data/models/weekly_xp_model.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cache inteligente para otimizar consultas
class SmartCache<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration defaultTtl;

  SmartCache({this.defaultTtl = const Duration(minutes: 10)});

  Future<T> get(
    String key,
    Future<T> Function() fetchFunction, {
    Duration? ttl,
    bool Function(T)? validator,
  }) async {
    final entry = _cache[key];
    final effectiveTtl = ttl ?? defaultTtl;

    if (entry != null &&
        DateTime.now().difference(entry.timestamp) < effectiveTtl &&
        (validator?.call(entry.data) ?? true)) {
      debugPrint('CACHE HIT: $key');
      return entry.data;
    }

    try {
      debugPrint('CACHE MISS: Buscando $key');
      final data = await fetchFunction();
      _cache[key] = CacheEntry(data, DateTime.now());
      return data;
    } catch (e) {
      if (entry != null) {
        debugPrint('Usando cache expirado para $key devido ao erro: $e');
        return entry.data;
      }
      rethrow;
    }
  }

  void invalidate(String key) => _cache.remove(key);
  void invalidatePattern(RegExp pattern) {
    _cache.removeWhere((key, _) => pattern.hasMatch(key));
  }
  void clear() => _cache.clear();
}

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  CacheEntry(this.data, this.timestamp);
}

class DatabaseService {
  final SmartCache<List<Module>> _moduleCache = SmartCache();
  final SmartCache<UserProfile> _profileCache = SmartCache(defaultTtl: const Duration(minutes: 5));
  final SmartCache<Set<int>> _completedLessonsCache = SmartCache(defaultTtl: const Duration(minutes: 3));

  /// Atualiza os detalhes do perfil de um utilizador de forma robusta
  Future<Result<UserProfile>> updateProfileDetails({
    required String userId,
    required String fullName,
    String? description,
    String? specialty,
  }) async {
    try {
      final updates = {
        'full_name': fullName.trim(),
        'description': description?.trim(),
        'specialty': specialty?.trim(),
      };

      final response = await supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      final profile = UserProfile.fromMap(response);
      _profileCache.invalidate('profile_$userId');
      return Success(profile);
    } catch (error) {
      return Failure('Erro ao atualizar perfil: $error');
    }
  }

  Future<Result<List<Module>>> getModulesAndLessons() async {
    try {
      final response = await supabase
          .from('modules')
          .select('*, lessons(*)')
          .order('id', ascending: true);

      final modules = (response as List)
          .map((data) => Module.fromMap(data))
          .toList();

      return Success(modules);
    } catch (error) {
      return Failure('Erro ao buscar módulos: $error');
    }
  }

  Future<Result<Set<int>>> getCompletedLessonIds(String userId) async {
    try {
      final response = await supabase
          .from('completed_lessons')
          .select('lesson_id')
          .eq('user_id', userId);

      final completedIds = (response as List)
          .map((data) => data['lesson_id'] as int)
          .toSet();

      return Success(completedIds);
    } catch (error) {
      return Failure('Erro ao buscar lições completadas: $error');
    }
  }

  Future<DatabaseResult<List<LessonStep>>> getStepsForLesson(int lessonId) async {
    final validation = DatabaseErrorHandler.validateInput(lessonId: lessonId);
    if (validation.isFailure) {
      return validation as DatabaseResult<List<LessonStep>>;
    }

    return DatabaseErrorHandler.execute<List<LessonStep>>(
      () async {
        final response = await supabase
            .from('lesson_steps')
            .select('*')
            .eq('lesson_id', lessonId)
            .order('step_index', ascending: true);

        return (response as List)
            .map((data) => LessonStep.fromMap(data))
            .toList();
      },
      operationName: 'getStepsForLesson',
      context: {'lessonId': lessonId},
    );
  }

  Future<DatabaseResult<void>> markLessonAsCompleted(String userId, int lessonId) async {
    final validation = DatabaseErrorHandler.validateInput(
      userId: userId,
      lessonId: lessonId,
    );
    if (validation.isFailure) {
      return validation;
    }

    return DatabaseErrorHandler.execute<void>(
      () async {
        await supabase.from('completed_lessons').insert({
          'user_id': userId,
          'lesson_id': lessonId,
        });

        // Invalidação cirúrgica - apenas dados do usuário específico
        _completedLessonsCache.invalidate('completed_lessons_$userId');
      },
      operationName: 'markLessonAsCompleted',
      context: {
        'userId': userId,
        'lessonId': lessonId,
      },
    );
  }

  Future<Result<UserProfile?>> getProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      final profile = response == null ? null : UserProfile.fromMap(response);
      return Success(profile);
    } catch (error) {
      return Failure('Erro ao buscar perfil: $error');
    }
  }

  Future<DatabaseResult<UserProfile>> createProfileOnLogin(User user) async {
    return DatabaseErrorHandler.execute<UserProfile>(
      () async {
        final response = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null && response.isNotEmpty) {
          final profile = UserProfile.fromMap(response);
          _profileCache.invalidate('profile_${user.id}'); // Atualizar cache
          return profile;
        } else {
          final fullName = user.userMetadata?['full_name']?.toString() ?? 'Músico Anônimo';

          final newProfileData = {
            'id': user.id,
            'full_name': fullName,
            'avatar_url': user.userMetadata?['avatar_url']?.toString(),
            'league': 'Bronze',
          };

          await supabase.from('profiles').insert(newProfileData);

          // Buscar o perfil recém-criado
          final createdProfileResult = await getProfile(user.id);

          if (createdProfileResult.isSuccess && createdProfileResult.data != null) {
            return createdProfileResult.data!;
          } else {
            // Fallback para dados locais se não conseguir buscar
            return UserProfile.fromMap(newProfileData);
          }
        }
      },
      operationName: 'createProfileOnLogin',
      context: {'userId': user.id},
    );
  }

  Future<Result<void>> updateStats({
    required String userId,
    int? points,
    int? lives,
    int? correctAnswers,
    int? wrongAnswers,
    int? currentStreak,
    String? lastPracticeDate,
    String? league,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (points != null) updates['points'] = points;
      if (lives != null) updates['lives'] = lives;
      if (correctAnswers != null) updates['correct_answers'] = correctAnswers;
      if (wrongAnswers != null) updates['wrong_answers'] = wrongAnswers;
      if (currentStreak != null) updates['current_streak'] = currentStreak;
      if (lastPracticeDate != null) updates['last_practice_date'] = lastPracticeDate;
      if (league != null) updates['league'] = league;

      if (updates.isNotEmpty) {
        await supabase.from('profiles').update(updates).eq('id', userId);
        _profileCache.invalidate('profile_$userId');
      }
      return const Success(null);
    } catch (error) {
      return Failure('Erro ao atualizar estatísticas: $error');
    }
  }

  Future<DatabaseResult<String>> uploadAvatar(String userId, File image) async {
    final validation = DatabaseErrorHandler.validateInput(userId: userId);
    if (validation.isFailure) {
      return validation as DatabaseResult<String>;
    }

    if (!image.existsSync()) {
      return const Failure(
        'Arquivo de imagem não encontrado.',
        errorCode: 'FILE_NOT_FOUND',
      );
    }

    // Verificar tamanho da imagem (máx 5MB)
    final fileSize = await image.length();
    if (fileSize > 5 * 1024 * 1024) {
      return const Failure(
        'Imagem muito grande. Tamanho máximo: 5MB.',
        errorCode: 'FILE_TOO_LARGE',
      );
    }

    return DatabaseErrorHandler.execute<String>(
      () async {
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final bucket = supabase.storage.from('lesson_assets');

        await bucket.upload(fileName, image);
        final publicUrl = bucket.getPublicUrl(fileName);

        await supabase
            .from('profiles')
            .update({'avatar_url': publicUrl})
            .eq('id', userId);

        // Invalidar cache do perfil
        _profileCache.invalidate('profile_$userId');

        return publicUrl;
      },
      operationName: 'uploadAvatar',
      context: {
        'userId': userId,
        'fileSize': fileSize,
      },
    );
  }

  Future<DatabaseResult<List<MelodicExercise>>> getMelodicExercises() async {
    return DatabaseErrorHandler.execute<List<MelodicExercise>>(
      () async {
        final response = await supabase
            .from('practice_melodies')
            .select('*')
            .order('difficulty', ascending: true)
            .order('id', ascending: true);

        return (response as List)
            .map((data) => MelodicExercise.fromMap(data))
            .toList();
      },
      operationName: 'getMelodicExercises',
    );
  }

  Future<DatabaseResult<void>> upsertWeeklyXp(String userId, int pointsToAdd) async {
    final validation = DatabaseErrorHandler.validateInput(userId: userId);
    if (validation.isFailure) {
      return validation;
    }

    if (pointsToAdd < 0) {
      return const Failure(
        'Pontos não podem ser negativos.',
        errorCode: 'INVALID_POINTS',
      );
    }

    return DatabaseErrorHandler.execute<void>(
      () async {
        await supabase.rpc('upsert_weekly_xp', params: {
          'p_user_id': userId,
          'p_xp_to_add': pointsToAdd,
        });
      },
      operationName: 'upsertWeeklyXp',
      context: {
        'userId': userId,
        'pointsToAdd': pointsToAdd,
      },
    );
  }

  Future<DatabaseResult<List<WeeklyXp>>> getLeagueLeaderboard(String userLeague) async {
    if (userLeague.trim().isEmpty) {
      return const Failure(
        'Liga do usuário não pode estar vazia.',
        errorCode: 'INVALID_LEAGUE',
      );
    }

    return DatabaseErrorHandler.execute<List<WeeklyXp>>(
      () async {
        final response = await supabase
            .from('weekly_xp')
            .select('*, profiles!inner(*)')
            .eq('profiles.league', userLeague)
            .order('xp', ascending: false)
            .limit(30);

        return (response as List)
            .where((data) => data['profiles'] != null)
            .map((data) => WeeklyXp.fromMap(data))
            .toList();
      },
      operationName: 'getLeagueLeaderboard',
      context: {'userLeague': userLeague},
    );
  }

  Future<DatabaseResult<List<HarmonicExercise>>> getHarmonicExercises() async {
    return DatabaseErrorHandler.execute<List<HarmonicExercise>>(
      () async {
        final response = await supabase
            .from('practice_harmonies')
            .select('*')
            .order('difficulty', ascending: true)
            .order('id', ascending: true);

        return (response as List)
            .map((data) => HarmonicExercise.fromMap(data))
            .toList();
      },
      operationName: 'getHarmonicExercises',
    );
  }

  Future<DatabaseResult<List<HarmonicProgression>>> getHarmonicProgressions() async {
    return DatabaseErrorHandler.execute<List<HarmonicProgression>>(
      () async {
        final response = await supabase
            .from('practice_progressions')
            .select('*')
            .order('difficulty', ascending: true)
            .order('id', ascending: true);

        return (response as List)
            .map((data) => HarmonicProgression.fromMap(data))
            .toList();
      },
      operationName: 'getHarmonicProgressions',
    );
  }

  /// Limpa todos os caches - útil para logout ou refresh
  void clearAllCaches() {
    _moduleCache.clear();
    _profileCache.clear();
    _completedLessonsCache.clear();
    debugPrint('Todos os caches do DatabaseService foram limpos.');
  }
}
