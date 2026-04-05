abstract class Failure {
  final String message;

  const Failure(this.message);
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure(super.message, {this.errors});
}

class NetworkFailure extends Failure {
  const NetworkFailure(
      [super.message = 'Tidak ada koneksi internet. Silakan coba lagi.']);
}
