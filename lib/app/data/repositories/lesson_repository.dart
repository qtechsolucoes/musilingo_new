// lib/app/data/repositories/lesson_repository.dart

import 'package:musilingo/app/core/repositories/base_repository.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/main.dart';

/// Repository para operações relacionadas a lições e módulos
class LessonRepository extends CacheableRepository<Lesson, int> {
  final _lessonCache = <int, Lesson>{};
  final _moduleCache = <int, Module>{};
  DateTime? _lastCacheUpdate;
  static const _cacheValidityDuration = Duration(minutes: 10);

  @override
  Future<Result<Lesson?>> findById(int id) async {
    try {
      // Verifica cache primeiro
      if (_isValidCache() && _lessonCache.containsKey(id)) {
        return Success(_lessonCache[id]);
      }

      final response =
          await supabase.from('lessons').select().eq('id', id).maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final lesson = Lesson.fromMap(response);
      _lessonCache[id] = lesson;

      return Success(lesson);
    } catch (error) {
      return Failure('Erro ao buscar lição: $error');
    }
  }

  @override
  Future<Result<List<Lesson>>> findAll() async {
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .order('order', ascending: true);

      final lessons =
          response.map<Lesson>((json) => Lesson.fromMap(json)).toList();

      // Atualiza cache
      for (final lesson in lessons) {
        _lessonCache[lesson.id] = lesson;
      }
      _lastCacheUpdate = DateTime.now();

      return Success(lessons);
    } catch (error) {
      return Failure('Erro ao buscar lições: $error');
    }
  }

  /// Busca módulos com suas lições
  Future<Result<List<Module>>> findModulesWithLessons() async {
    try {
      // Verifica cache primeiro
      if (_isValidCache() && _moduleCache.isNotEmpty) {
        return Success(_moduleCache.values.toList());
      }

      final response = await supabase.from('modules').select('''
            *,
            lessons (*)
          ''').order('order', ascending: true);

      final modules =
          response.map<Module>((json) => Module.fromMap(json)).toList();

      // CORREÇÃO: Lógica de atualização de cache para ser atômica.
      // Primeiro, preparamos os novos caches temporariamente.
      final newModuleCache = <int, Module>{};
      final newLessonCache = <int, Lesson>{};

      for (final module in modules) {
        newModuleCache[module.id] = module;
        for (final lesson in module.lessons) {
          newLessonCache[lesson.id] = lesson;
        }
      }

      // Agora, limpamos os caches antigos e adicionamos os novos dados de uma só vez.
      _moduleCache.clear();
      _lessonCache.clear();
      _moduleCache.addAll(newModuleCache);
      _lessonCache.addAll(newLessonCache);
      _lastCacheUpdate = DateTime.now();
      // FIM DA CORREÇÃO

      return Success(modules);
    } catch (error) {
      return Failure('Erro ao buscar módulos: $error');
    }
  }

  /// Busca lições de um módulo específico
  Future<Result<List<Lesson>>> findLessonsByModule(int moduleId) async {
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .eq('module_id', moduleId)
          .order('order', ascending: true);

      final lessons =
          response.map<Lesson>((json) => Lesson.fromMap(json)).toList();

      return Success(lessons);
    } catch (error) {
      return Failure('Erro ao buscar lições do módulo: $error');
    }
  }

  /// Busca lições completadas por um usuário
  Future<Result<List<int>>> findCompletedLessonIds(String userId) async {
    try {
      final response = await supabase
          .from('completed_lessons')
          .select('lesson_id')
          .eq('user_id', userId);

      final lessonIds =
          response.map<int>((json) => json['lesson_id'] as int).toList();

      return Success(lessonIds);
    } catch (error) {
      return Failure('Erro ao buscar lições completadas: $error');
    }
  }

  /// Marca uma lição como completada
  Future<Result<bool>> markLessonAsCompleted(
      String userId, int lessonId) async {
    try {
      await supabase.from('completed_lessons').upsert({
        'user_id': userId,
        'lesson_id': lessonId,
        'completed_at': DateTime.now().toIso8601String(),
      });

      return const Success(true);
    } catch (error) {
      return Failure('Erro ao marcar lição como completada: $error');
    }
  }

  /// Busca progresso do usuário
  Future<Result<Map<String, dynamic>>> findUserProgress(String userId) async {
    try {
      final completedResult = await findCompletedLessonIds(userId);
      if (completedResult.isFailure) {
        return Failure(completedResult.errorMessage!);
      }

      final allLessonsResult = await findAll();
      if (allLessonsResult.isFailure) {
        return Failure(allLessonsResult.errorMessage!);
      }

      final completedIds = completedResult.data;
      final totalLessons = allLessonsResult.data.length;
      final completedCount = completedIds.length;
      final progressPercentage =
          totalLessons > 0 ? (completedCount / totalLessons * 100).round() : 0;

      return Success({
        'total_lessons': totalLessons,
        'completed_lessons': completedCount,
        'progress_percentage': progressPercentage,
        'completed_lesson_ids': completedIds,
      });
    } catch (error) {
      return Failure('Erro ao calcular progresso: $error');
    }
  }

  /// Busca próxima lição a ser completada
  Future<Result<Lesson?>> findNextLesson(String userId) async {
    try {
      final completedResult = await findCompletedLessonIds(userId);
      if (completedResult.isFailure) {
        return Failure(completedResult.errorMessage!);
      }

      final allLessonsResult = await findAll();
      if (allLessonsResult.isFailure) {
        return Failure(allLessonsResult.errorMessage!);
      }

      final completedIds = completedResult.data;
      final allLessons = allLessonsResult.data;

      // Encontra a primeira lição não completada
      final nextLesson = allLessons.firstWhere(
        (lesson) => !completedIds.contains(lesson.id),
        orElse: () => throw 'NoNextLesson',
      );

      return Success(nextLesson);
    } catch (error) {
      if (error == 'NoNextLesson') {
        return const Success(null); // Todas as lições foram completadas
      }
      return Failure('Erro ao buscar próxima lição: $error');
    }
  }

  @override
  Future<Result<Lesson>> create(Lesson lesson) async {
    try {
      final response = await supabase
          .from('lessons')
          .insert(lesson.toMap())
          .select()
          .single();

      final createdLesson = Lesson.fromMap(response);
      _lessonCache[createdLesson.id] = createdLesson;

      return Success(createdLesson);
    } catch (error) {
      return Failure('Erro ao criar lição: $error');
    }
  }

  @override
  Future<Result<Lesson>> update(int id, Lesson lesson) async {
    try {
      final response = await supabase
          .from('lessons')
          .update(lesson.toMap())
          .eq('id', id)
          .select()
          .single();

      final updatedLesson = Lesson.fromMap(response);
      _lessonCache[id] = updatedLesson;

      return Success(updatedLesson);
    } catch (error) {
      return Failure('Erro ao atualizar lição: $error');
    }
  }

  @override
  Future<Result<bool>> delete(int id) async {
    try {
      await supabase.from('lessons').delete().eq('id', id);

      _lessonCache.remove(id);

      return const Success(true);
    } catch (error) {
      return Failure('Erro ao deletar lição: $error');
    }
  }

  @override
  Future<Result<List<Lesson>>> findWithPagination({
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = supabase.from('lessons').select();

      // Apply filters first
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Then apply ordering and range
      final offset = (page - 1) * limit;
      final response = await query
          .order('order', ascending: true)
          .range(offset, offset + limit - 1);

      final lessons =
          response.map<Lesson>((json) => Lesson.fromMap(json)).toList();

      return Success(lessons);
    } catch (error) {
      return Failure('Erro ao buscar lições paginadas: $error');
    }
  }

  @override
  Future<Result<int>> count() async {
    try {
      final response = await supabase.from('lessons').select('id').count();

      return Success(response.count);
    } catch (error) {
      return Failure('Erro ao contar lições: $error');
    }
  }

  @override
  Future<void> clearCache() async {
    _lessonCache.clear();
    _moduleCache.clear();
    _lastCacheUpdate = null;
  }

  @override
  Future<void> invalidateCache(int id) async {
    _lessonCache.remove(id);
  }

  @override
  Future<Result<Lesson?>> refreshCache(int id) async {
    _lessonCache.remove(id);
    return await findById(id);
  }

  /// Limpa cache dos módulos
  Future<void> clearModuleCache() async {
    _moduleCache.clear();
    _lastCacheUpdate = null;
  }

  bool _isValidCache() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
  }
}
