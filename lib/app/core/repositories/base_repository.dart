// lib/app/core/repositories/base_repository.dart

import 'package:musilingo/app/core/result.dart';

/// Interface base para todos os repositories
/// Define operações CRUD comuns e padrões de erro
abstract class BaseRepository<T, ID> {
  /// Busca um item por ID
  Future<Result<T?>> findById(ID id);

  /// Busca todos os itens
  Future<Result<List<T>>> findAll();

  /// Cria um novo item
  Future<Result<T>> create(T item);

  /// Atualiza um item existente
  Future<Result<T>> update(ID id, T item);

  /// Remove um item por ID
  Future<Result<bool>> delete(ID id);

  /// Busca itens com paginação
  Future<Result<List<T>>> findWithPagination({
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? filters,
  });

  /// Conta total de itens
  Future<Result<int>> count();
}

/// Repository específico para operações em cache
abstract class CacheableRepository<T, ID> extends BaseRepository<T, ID> {
  /// Limpa o cache
  Future<void> clearCache();

  /// Invalida cache para um item específico
  Future<void> invalidateCache(ID id);

  /// Força refresh do cache
  Future<Result<T?>> refreshCache(ID id);
}

/// Repository para operações em tempo real
abstract class RealtimeRepository<T, ID> extends BaseRepository<T, ID> {
  /// Stream de mudanças em tempo real
  Stream<List<T>> watchAll();

  /// Stream de mudanças para um item específico
  Stream<T?> watchById(ID id);

  /// Para de escutar mudanças
  Future<void> stopWatching();
}