class ServerException implements Exception {
  final String message;
  final int statusCode;

  const ServerException({
    this.message = 'error_server',
    this.statusCode = 0,
  });

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class UnauthorizedException extends ServerException {
  const UnauthorizedException()
      : super(message: 'error_session_expired', statusCode: 401);
}

class ClientException extends ServerException {
  const ClientException({String message = 'unknown_error', int statusCode = 400})
      : super(message: message, statusCode: statusCode);
}

class ValidationException extends ServerException {
  const ValidationException({String message = 'error_validation_failed', int statusCode = 422})
      : super(message: message, statusCode: statusCode);
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error occurred'});

  @override
  String toString() => 'CacheException: $message';
}
