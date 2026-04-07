import '../entities/absensiHariIni.dart';
import '../repositories/absensiRepository.dart';

class GetTodayStatusUseCase {
  final AbsensiRepository _repository;
  const GetTodayStatusUseCase(this._repository);

  Future<AbsensiHariIni> call({required String token}) =>
      _repository.getTodayStatus(token: token);
}
