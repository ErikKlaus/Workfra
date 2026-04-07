import '../repositories/absensiRepository.dart';

class CheckOutUseCase {
  final AbsensiRepository _repository;
  const CheckOutUseCase(this._repository);

  Future<Map<String, dynamic>> call({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) => _repository.checkOut(
    token: token,
    latitude: latitude,
    longitude: longitude,
    address: address,
  );
}
