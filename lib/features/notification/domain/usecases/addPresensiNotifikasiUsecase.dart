import '../repositories/notifikasiRepository.dart';

class AddPresensiNotifikasiUseCase {
  final NotifikasiRepository _repository;
  const AddPresensiNotifikasiUseCase(this._repository);

  Future<void> call({required bool isCheckIn, required String? timeLabel}) {
    return _repository.addPresensiNotifikasi(
      isCheckIn: isCheckIn,
      timeLabel: timeLabel,
    );
  }
}
