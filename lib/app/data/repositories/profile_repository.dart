// lib/app/data/repositories/profile_repository.dart

import 'package:musilingo/app/core/repositories/base_repository.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/main.dart';

/// Repository para operações relacionadas a perfis de usuário
class ProfileRepository extends CacheableRepository<UserProfile, String> {
  final _cache = <String, UserProfile>{};
  DateTime? _lastCacheUpdate;
  static const _cacheValidityDuration = Duration(minutes: 5);

  @override
  Future<Result<UserProfile?>> findById(String id) async {
    try {
      // Verifica cache primeiro
      if (_isValidCache() && _cache.containsKey(id)) {
        return Success(_cache[id]);
      }

      final response =
          await supabase.from('profiles').select().eq('id', id).maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final profile = UserProfile.fromMap(response);
      _cache[id] = profile;
      _lastCacheUpdate = DateTime.now();

      return Success(profile);
    } catch (error) {
      return Failure('Erro ao buscar perfil: $error');
    }
  }

  @override
  Future<Result<List<UserProfile>>> findAll() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final profiles = response
          .map<UserProfile>((json) => UserProfile.fromMap(json))
          .toList();

      // Atualiza cache com todos os perfis
      for (final profile in profiles) {
        _cache[profile.id] = profile;
      }
      _lastCacheUpdate = DateTime.now();

      return Success(profiles);
    } catch (error) {
      return Failure('Erro ao buscar perfis: $error');
    }
  }

  @override
  Future<Result<UserProfile>> create(UserProfile profile) async {
    try {
      final response = await supabase
          .from('profiles')
          .insert(profile.toMap())
          .select()
          .single();

      final createdProfile = UserProfile.fromMap(response);
      _cache[createdProfile.id] = createdProfile;

      return Success(createdProfile);
    } catch (error) {
      return Failure('Erro ao criar perfil: $error');
    }
  }

  @override
  Future<Result<UserProfile>> update(String id, UserProfile profile) async {
    try {
      final response = await supabase
          .from('profiles')
          .update(profile.toMap())
          .eq('id', id)
          .select()
          .single();

      final updatedProfile = UserProfile.fromMap(response);
      _cache[id] = updatedProfile;

      return Success(updatedProfile);
    } catch (error) {
      return Failure('Erro ao atualizar perfil: $error');
    }
  }

  @override
  Future<Result<bool>> delete(String id) async {
    try {
      await supabase.from('profiles').delete().eq('id', id);

      _cache.remove(id);

      return const Success(true);
    } catch (error) {
      return Failure('Erro ao deletar perfil: $error');
    }
  }

  @override
  Future<Result<List<UserProfile>>> findWithPagination({
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = supabase.from('profiles').select();

      // Aplica filtros se fornecidos
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Aplica ordenação e range
      final offset = (page - 1) * limit;
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final profiles = response
          .map<UserProfile>((json) => UserProfile.fromMap(json))
          .toList();

      return Success(profiles);
    } catch (error) {
      return Failure('Erro ao buscar perfis paginados: $error');
    }
  }

  @override
  Future<Result<int>> count() async {
    try {
      final response = await supabase.from('profiles').select('id').count();

      return Success(response.count);
    } catch (error) {
      return Failure('Erro ao contar perfis: $error');
    }
  }

  /// Busca perfis por especialidade (para professores)
  Future<Result<List<UserProfile>>> findBySpecialty(String specialty) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('specialty', specialty)
          .eq('role_id', 2); // 2 = Professor

      final profiles = response
          .map<UserProfile>((json) => UserProfile.fromMap(json))
          .toList();

      return Success(profiles);
    } catch (error) {
      return Failure('Erro ao buscar perfis por especialidade: $error');
    }
  }

  /// Busca perfis por liga
  Future<Result<List<UserProfile>>> findByLeague(String league) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('league', league)
          .order('points', ascending: false);

      final profiles = response
          .map<UserProfile>((json) => UserProfile.fromMap(json))
          .toList();

      return Success(profiles);
    } catch (error) {
      return Failure('Erro ao buscar perfis por liga: $error');
    }
  }

  /// Busca ranking de usuários
  Future<Result<List<UserProfile>>> findRanking({int limit = 50}) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('points', ascending: false)
          .limit(limit);

      final profiles = response
          .map<UserProfile>((json) => UserProfile.fromMap(json))
          .toList();

      return Success(profiles);
    } catch (error) {
      return Failure('Erro ao buscar ranking: $error');
    }
  }

  /// Atualiza estatísticas do usuário
  Future<Result<UserProfile>> updateStats(
    String userId, {
    int? pointsToAdd,
    int? livesToAdd,
    bool? incrementCorrectAnswers,
    bool? incrementWrongAnswers,
    int? newStreak,
  }) async {
    try {
      // Primeiro busca o perfil atual
      final currentResult = await findById(userId);
      final currentProfile = switch (currentResult) {
        Success<UserProfile?>(data: final profile) => profile,
        Failure<UserProfile?>(errorMessage: final error) =>
          throw Exception('Erro ao buscar perfil atual: $error'),
      };

      if (currentProfile == null) {
        return const Failure('Perfil não encontrado');
      }

      // Calcula os novos valores
      var updateData = <String, dynamic>{};

      if (pointsToAdd != null) {
        updateData['points'] = currentProfile.points + pointsToAdd;
      }
      if (livesToAdd != null) {
        updateData['lives'] = currentProfile.lives + livesToAdd;
      }
      if (incrementCorrectAnswers == true) {
        updateData['correct_answers'] = currentProfile.correctAnswers + 1;
      }
      if (incrementWrongAnswers == true) {
        updateData['wrong_answers'] = currentProfile.wrongAnswers + 1;
      }
      if (newStreak != null) {
        updateData['current_streak'] = newStreak;
      }

      final response = await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      final updatedProfile = UserProfile.fromMap(response);
      _cache[userId] = updatedProfile;

      return Success(updatedProfile);
    } catch (error) {
      return Failure('Erro ao atualizar estatísticas: $error');
    }
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  @override
  Future<void> invalidateCache(String id) async {
    _cache.remove(id);
  }

  @override
  Future<Result<UserProfile?>> refreshCache(String id) async {
    _cache.remove(id);
    return await findById(id);
  }

  bool _isValidCache() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
  }
}
