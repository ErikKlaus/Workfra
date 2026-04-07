import '../repositories/absensiRepository.dart';

class CheckInUseCase {
  final AbsensiRepository _repository;
  const CheckInUseCase(this._repository);

  Future<Map<String, dynamic>> call({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) => _repository.checkIn(
    token: token,
    latitude: latitude,
    longitude: longitude,
    address: address,
  );
}
