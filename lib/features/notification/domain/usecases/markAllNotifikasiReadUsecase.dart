import '../repositories/notifikasiRepository.dart';

class MarkAllNotifikasiReadUseCase {
  final NotifikasiRepository _repository;
  const MarkAllNotifikasiReadUseCase(this._repository);

  Future<void> call() {
    return _repository.markAllAsRead();
  }
}
