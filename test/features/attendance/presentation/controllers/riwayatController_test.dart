import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tugas_16_flutter/core/error/exceptions.dart';
import 'package:tugas_16_flutter/core/services/layananPenyimpanan.dart';
import 'package:tugas_16_flutter/features/attendance/domain/entities/absensiHariIni.dart';
import 'package:tugas_16_flutter/features/attendance/domain/repositories/absensiRepository.dart';
import 'package:tugas_16_flutter/features/attendance/domain/usecases/getAbsensiHistoryUsecase.dart';
import 'package:tugas_16_flutter/features/attendance/domain/usecases/getTodayStatusUsecase.dart';
import 'package:tugas_16_flutter/features/attendance/presentation/providers/riwayatProvider.dart';
import 'package:tugas_16_flutter/features/auth/domain/entities/jenisKelamin.dart';
import 'package:tugas_16_flutter/features/auth/domain/entities/opsiDropdown.dart';
import 'package:tugas_16_flutter/features/auth/domain/entities/user.dart';
import 'package:tugas_16_flutter/features/auth/domain/repositories/authRepository.dart';
import 'package:tugas_16_flutter/features/home/domain/entities/riwayat.dart';
import 'package:tugas_16_flutter/features/leave/domain/entities/izin.dart';
import 'package:tugas_16_flutter/features/leave/domain/repositories/izinRepository.dart';
import 'package:tugas_16_flutter/features/leave/domain/usecases/getIzinHistoryUsecase.dart';

class FakeAbsensiRepository implements AbsensiRepository {
  List<Riwayat> historyResult = const [];
  AbsensiHariIni todayResult = AbsensiHariIni.empty;
  Object? historyError;
  Object? todayError;
  int historyCalls = 0;
  int todayCalls = 0;

  @override
  Future<List<Riwayat>> getHistory({required String token}) async {
    historyCalls += 1;
    if (historyError != null) {
      throw historyError!;
    }
    return historyResult;
  }

  @override
  Future<AbsensiHariIni> getTodayStatus({required String token}) async {
    todayCalls += 1;
    if (todayError != null) {
      throw todayError!;
    }
    return todayResult;
  }

  @override
  Future<void> deleteAbsen({required String token, required int id}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) {
    throw UnimplementedError();
  }
}

class FakeIzinRepository implements IzinRepository {
  List<Izin> historyResult = const [];
  Object? historyError;
  int historyCalls = 0;

  @override
  Future<List<Izin>> getIzinHistory({required String token}) async {
    historyCalls += 1;
    if (historyError != null) {
      throw historyError!;
    }
    return historyResult;
  }

  @override
  Future<void> createIzin({
    required String token,
    required String date,
    required String type,
    required String reason,
  }) {
    throw UnimplementedError();
  }
}

class FakeAuthRepository implements AuthRepository {
  String? token;
  int getTokenCalls = 0;

  @override
  Future<String?> getToken() async {
    getTokenCalls += 1;
    return token;
  }

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> logout() async {
    token = null;
  }

  @override
  Future<void> forgotPassword({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<List<OpsiDropdown>> getBatches() {
    throw UnimplementedError();
  }

  @override
  Future<List<JenisKelamin>> getGenders() {
    throw UnimplementedError();
  }

  @override
  Future<List<OpsiDropdown>> getTrainings() {
    throw UnimplementedError();
  }

  @override
  Future<User> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> uploadPhoto({required String filePath, required String token}) {
    throw UnimplementedError();
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAbsensiRepository fakeAbsensiRepo;
  late FakeIzinRepository fakeIzinRepo;
  late FakeAuthRepository fakeAuthRepo;
  late StorageService storageService;
  late RiwayatProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    fakeAbsensiRepo = FakeAbsensiRepository();
    fakeAbsensiRepo.todayError = Exception('skip today status in most tests');
    fakeIzinRepo = FakeIzinRepository();
    fakeAuthRepo = FakeAuthRepository();
    storageService = StorageService(prefs);

    provider = RiwayatProvider(
      getAbsensiHistoryUseCase: GetAbsensiHistoryUseCase(fakeAbsensiRepo),
      getTodayStatusUseCase: GetTodayStatusUseCase(fakeAbsensiRepo),
      getIzinHistoryUseCase: GetIzinHistoryUseCase(fakeIzinRepo),
      authRepository: fakeAuthRepo,
      storageService: storageService,
    );
  });

  group('RiwayatProvider.combineData', () {
    test('merge presensi + izin and sort descending by date', () async {
      fakeAuthRepo.token = 'token';
      fakeAbsensiRepo.historyResult = [
        Riwayat(
          id: 1,
          tanggal: DateTime(2026, 4, 1),
          jamMasuk: '08:00',
          jamKeluar: '17:00',
          status: 'present',
        ),
      ];
      fakeIzinRepo.historyResult = [
        Izin(
          id: 2,
          type: 'izin',
          date: DateTime(2026, 4, 5),
          reason: 'Acara keluarga',
          status: StatusIzin.pending,
        ),
      ];

      await provider.combineData();

      expect(provider.errorMessage, isNull);
      expect(provider.combinedData.length, 2);
      expect(provider.combinedData.first.jenis, JenisRiwayatGabungan.izin);
      expect(provider.top3CombinedData.length, 2);
    });

    test('return session expired when token is empty', () async {
      fakeAuthRepo.token = null;

      await provider.combineData();

      expect(provider.errorMessage, 'error_session_expired');
      expect(provider.combinedData, isEmpty);
      expect(fakeAbsensiRepo.historyCalls, 0);
      expect(fakeIzinRepo.historyCalls, 0);
    });

    test('use cache when server throws ServerException', () async {
      fakeAuthRepo.token = 'token';
      fakeAbsensiRepo.historyResult = [
        Riwayat(
          id: 10,
          tanggal: DateTime(2026, 4, 2),
          jamMasuk: '08:00',
          jamKeluar: '17:00',
          status: 'present',
        ),
      ];
      fakeIzinRepo.historyResult = const [];

      await provider.combineData(forceRefresh: true);
      expect(provider.combinedData, isNotEmpty);

      fakeAbsensiRepo.historyError = ServerException(
        message: 'error_server_unavailable',
        statusCode: 503,
      );

      await provider.combineData(forceRefresh: true);

      expect(provider.errorMessage, 'error_server_unavailable');
      expect(provider.combinedData, isNotEmpty);
      expect(
        provider.combinedData.any((item) => item.presensi?.id == 10),
        isTrue,
      );
    });

    test('skip refetch when cache is still fresh', () async {
      fakeAuthRepo.token = 'token';
      fakeAbsensiRepo.historyResult = [
        Riwayat(
          id: 1,
          tanggal: DateTime(2026, 4, 1),
          jamMasuk: '08:00',
          jamKeluar: '17:00',
          status: 'present',
        ),
      ];
      fakeIzinRepo.historyResult = const [];

      await provider.combineData();
      await provider.combineData();

      expect(fakeAbsensiRepo.historyCalls, 1);
      expect(fakeIzinRepo.historyCalls, 1);
    });

    test('append today fallback when no attendance record for today', () async {
      fakeAuthRepo.token = 'token';
      fakeAbsensiRepo.todayError = null;
      fakeAbsensiRepo.historyResult = [
        Riwayat(
          id: 99,
          tanggal: DateTime(2026, 4, 1),
          jamMasuk: '08:00',
          jamKeluar: '17:00',
          status: 'present',
        ),
      ];
      fakeAbsensiRepo.todayResult = AbsensiHariIni(
        hasCheckedIn: true,
        hasCheckedOut: false,
        checkInTime: '08:15',
        checkOutTime: null,
        serverNow: DateTime(2026, 4, 10, 9, 0),
        status: 'hadir',
      );
      fakeIzinRepo.historyResult = const [];

      await provider.combineData(forceRefresh: true);

      final hasTodayFallback = provider.combinedData.any(
        (item) =>
            item.jenis == JenisRiwayatGabungan.presensi &&
            item.tanggal.year == 2026 &&
            item.tanggal.month == 4 &&
            item.tanggal.day == 10,
      );

      expect(hasTodayFallback, isTrue);
    });
  });

  group('RiwayatProvider.silentRefresh', () {
    test('update data silently when request succeeds', () async {
      fakeAuthRepo.token = 'token';
      fakeAbsensiRepo.historyResult = [
        Riwayat(
          id: 1,
          tanggal: DateTime(2026, 4, 1),
          jamMasuk: '08:00',
          jamKeluar: '17:00',
          status: 'present',
        ),
      ];
      fakeIzinRepo.historyResult = const [];
      await provider.combineData(forceRefresh: true);

      fakeAbsensiRepo.historyResult = [
        Riwayat(
          id: 2,
          tanggal: DateTime(2026, 4, 8),
          jamMasuk: '08:00',
          jamKeluar: '17:00',
          status: 'present',
        ),
      ];

      await provider.silentRefresh();

      expect(
        provider.combinedData.any((item) => item.presensi?.id == 2),
        isTrue,
      );
      expect(provider.errorMessage, isNull);
    });

    test('keep old data when silent refresh fails', () async {
      fakeAuthRepo.token = 'token';
      fakeAbsensiRepo.historyResult = [
        Riwayat(
          id: 1,
          tanggal: DateTime(2026, 4, 1),
          jamMasuk: '08:00',
          jamKeluar: '17:00',
          status: 'present',
        ),
      ];
      fakeIzinRepo.historyResult = const [];
      await provider.combineData(forceRefresh: true);

      fakeAbsensiRepo.historyError = Exception('network error');

      await provider.silentRefresh();

      expect(
        provider.combinedData.any((item) => item.presensi?.id == 1),
        isTrue,
      );
    });
  });
}
