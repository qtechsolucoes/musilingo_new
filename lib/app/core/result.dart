// lib/app/core/result.dart

/// Classe base para representar resultados de operações que podem falhar
sealed class Result<T> {
  const Result();
}

/// Representa um resultado bem-sucedido
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Representa um resultado com falha
class Failure<T> extends Result<T> {
  final String message;
  final String? errorCode;
  final Exception? originalException;
  final Map<String, dynamic>? context;

  const Failure(
    this.message, {
    this.errorCode,
    this.originalException,
    this.context,
  });

  @override
  String toString() => 'Failure: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
}

/// Extensão para facilitar o uso dos Results
extension ResultExtensions<T> on Result<T> {
  /// Verifica se o resultado é bem-sucedido
  bool get isSuccess => this is Success<T>;

  /// Verifica se o resultado é falha
  bool get isFailure => this is Failure<T>;

  /// Obtém os dados se for sucesso, null caso contrário
  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>() => null,
  };

  /// Obtém os dados ou lança exceção se for falha
  T get data => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>(message: final message) => throw Exception(message),
  };

  /// Obtém a mensagem de erro se for falha
  String? get errorMessage => switch (this) {
    Success<T>() => null,
    Failure<T>(message: final message) => message,
  };

  /// Mapeia o valor se for sucesso
  Result<U> map<U>(U Function(T) mapper) => switch (this) {
    Success<T>(data: final data) => Success(mapper(data)),
    Failure<T>() => Failure<U>(
      (this as Failure<T>).message,
      errorCode: (this as Failure<T>).errorCode,
      originalException: (this as Failure<T>).originalException,
      context: (this as Failure<T>).context,
    ),
  };

  /// Executa uma função se for sucesso
  Result<U> flatMap<U>(Result<U> Function(T) mapper) => switch (this) {
    Success<T>(data: final data) => mapper(data),
    Failure<T>() => Failure<U>(
      (this as Failure<T>).message,
      errorCode: (this as Failure<T>).errorCode,
      originalException: (this as Failure<T>).originalException,
      context: (this as Failure<T>).context,
    ),
  };

  /// Executa callback baseado no resultado
  void fold(
    void Function(Failure<T>) onFailure,
    void Function(T) onSuccess,
  ) {
    switch (this) {
      case Success<T>(data: final data):
        onSuccess(data);
      case Failure<T> failure:
        onFailure(failure);
    }
  }
}

/// Tipos específicos para operações do banco de dados
typedef DatabaseResult<T> = Result<T>;

/// Extensions para Result com métodos convenientes
extension ResultMethods<T> on Result<T> {
  static Success<T> success<T>(T data) => Success(data);

  static Failure<T> failure<T>(
    String message, {
    String? errorCode,
    Exception? originalException,
    Map<String, dynamic>? context,
  }) => Failure(
    message,
    errorCode: errorCode,
    originalException: originalException,
    context: context,
  );
}

/// Factory methods para criar Results mais facilmente
class ResultFactory {
  static Success<T> success<T>(T data) => Success(data);

  static Failure<T> failure<T>(
    String message, {
    String? errorCode,
    Exception? originalException,
    Map<String, dynamic>? context,
  }) => Failure(
    message,
    errorCode: errorCode,
    originalException: originalException,
    context: context,
  );

  static Failure<T> networkFailure<T>([String? details]) => Failure(
    'Erro de conexão com o servidor${details != null ? ': $details' : ''}',
    errorCode: 'NETWORK_ERROR',
  );

  static Failure<T> validationFailure<T>(String message) => Failure(
    message,
    errorCode: 'VALIDATION_ERROR',
  );

  static Failure<T> authFailure<T>([String? details]) => Failure(
    'Erro de autenticação${details != null ? ': $details' : ''}',
    errorCode: 'AUTH_ERROR',
  );

  static Failure<T> notFoundFailure<T>([String? resource]) => Failure(
    '${resource ?? 'Recurso'} não encontrado',
    errorCode: 'NOT_FOUND',
  );

  static Failure<T> permissionFailure<T>([String? details]) => Failure(
    'Permissão negada${details != null ? ': $details' : ''}',
    errorCode: 'PERMISSION_DENIED',
  );
}