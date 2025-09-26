// lib/app/core/database_error_handler.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'result.dart';

/// Utilitário para converter exceções em Results padronizados
class DatabaseErrorHandler {
  /// Executa uma operação do banco de dados e converte erros em Results
  static Future<DatabaseResult<T>> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } on SocketException catch (e) {
      debugPrint('Erro de rede em ${operationName ?? 'operação'}: $e');
      return Failure(
        'Sem conexão com a internet. Verifique sua conexão.',
        errorCode: 'NETWORK_ERROR',
        originalException: e,
        context: context,
      );
    } on PostgrestException catch (e) {
      debugPrint('Erro do Supabase em ${operationName ?? 'operação'}: ${e.message}');
      return _handlePostgresError<T>(e, context);
    } on AuthException catch (e) {
      debugPrint('Erro de autenticação em ${operationName ?? 'operação'}: ${e.message}');
      return Failure(
        'Erro de autenticação: ${e.message}',
        errorCode: 'AUTH_ERROR',
        originalException: e,
        context: context,
      );
    } on StorageException catch (e) {
      debugPrint('Erro de storage em ${operationName ?? 'operação'}: ${e.message}');
      return Failure(
        'Erro no upload: ${e.message}',
        errorCode: 'STORAGE_ERROR',
        originalException: e,
        context: context,
      );
    } catch (e) {
      debugPrint('Erro inesperado em ${operationName ?? 'operação'}: $e');
      return Failure(
        'Erro inesperado: ${e.toString()}',
        errorCode: 'UNKNOWN_ERROR',
        originalException: e is Exception ? e : Exception(e.toString()),
        context: context,
      );
    }
  }

  /// Trata erros específicos do PostgreSQL/Supabase
  static Failure<T> _handlePostgresError<T>(
    PostgrestException e,
    Map<String, dynamic>? context,
  ) {
    // Códigos de erro PostgreSQL comuns
    switch (e.code) {
      case '23505': // Violação de unique constraint
        return Failure(
          'Este registro já existe no sistema.',
          errorCode: 'DUPLICATE_ERROR',
          originalException: e,
          context: context,
        );
      case '23503': // Violação de foreign key
        return Failure(
          'Erro de referência: registro relacionado não encontrado.',
          errorCode: 'FOREIGN_KEY_ERROR',
          originalException: e,
          context: context,
        );
      case '23502': // Violação de not null
        return Failure(
          'Campo obrigatório não preenchido.',
          errorCode: 'REQUIRED_FIELD_ERROR',
          originalException: e,
          context: context,
        );
      case '42501': // Insufficient privilege
        return Failure(
          'Permissão insuficiente para realizar esta operação.',
          errorCode: 'PERMISSION_ERROR',
          originalException: e,
          context: context,
        );
      case '42P01': // Table doesn't exist
        return Failure(
          'Erro interno: tabela não encontrada.',
          errorCode: 'TABLE_NOT_FOUND',
          originalException: e,
          context: context,
        );
      default:
        // Erro genérico do PostgreSQL
        return Failure(
          'Erro no banco de dados: ${e.message}',
          errorCode: e.code ?? 'POSTGRES_ERROR',
          originalException: e,
          context: context,
        );
    }
  }

  /// Valida se um ID de usuário é válido
  static bool isValidUserId(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    // UUID v4 pattern
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
    );
    return uuidPattern.hasMatch(userId);
  }

  /// Valida dados de entrada básicos
  static DatabaseResult<void> validateInput({
    String? userId,
    String? fullName,
    int? lessonId,
  }) {
    if (userId != null && !isValidUserId(userId)) {
      return const Failure(
        'ID de usuário inválido.',
        errorCode: 'INVALID_USER_ID',
      );
    }

    if (fullName != null && fullName.trim().isEmpty) {
      return const Failure(
        'Nome não pode estar vazio.',
        errorCode: 'INVALID_FULL_NAME',
      );
    }

    if (fullName != null && fullName.trim().length > 100) {
      return const Failure(
        'Nome muito longo (máximo 100 caracteres).',
        errorCode: 'FULL_NAME_TOO_LONG',
      );
    }

    if (lessonId != null && lessonId <= 0) {
      return const Failure(
        'ID de lição inválido.',
        errorCode: 'INVALID_LESSON_ID',
      );
    }

    return const Success(null);
  }
}