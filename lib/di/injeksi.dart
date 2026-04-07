import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/layananPenyimpanan.dart';
import '../core/services/lokasiService.dart';
import '../features/auth/data/datasources/authLocalDatasource.dart';
import '../features/auth/data/datasources/authRemoteDatasource.dart';
import '../features/auth/data/repositories/authRepositoryImpl.dart';
import '../features/auth/domain/repositories/authRepository.dart';
import '../features/auth/domain/usecases/lupaPasswordUsecase.dart';
import '../features/auth/domain/usecases/getBatchesUsecase.dart';
import '../features/auth/domain/usecases/getGendersUsecase.dart';
import '../features/auth/domain/usecases/getTrainingsUsecase.dart';
import '../features/auth/domain/usecases/loginUsecase.dart';
import '../features/auth/domain/usecases/registerUsecase.dart';
import '../features/auth/domain/usecases/resetPasswordUsecase.dart';
import '../features/auth/domain/usecases/uploadFotoUsecase.dart';
import '../features/auth/domain/usecases/verifikasiOtpUsecase.dart';
import '../features/auth/presentation/providers/authProvider.dart';
import '../features/home/presentation/providers/berandaProvider.dart';
import '../features/profile/data/datasources/profileRemoteDatasource.dart';
import '../features/profile/data/repositories/profileRepositoryImpl.dart';
import '../features/profile/domain/repositories/profileRepository.dart';
import '../features/profile/domain/usecases/getProfileUsecase.dart';
import '../features/profile/domain/usecases/updateProfileUsecase.dart';
import '../features/profile/domain/usecases/uploadProfilePhotoUsecase.dart';
import '../features/profile/presentation/providers/profileProvider.dart';
import '../features/notification/data/datasources/notifikasiLocalDatasource.dart';
import '../features/notification/data/repositories/notifikasiRepositoryImpl.dart';
import '../features/notification/domain/repositories/notifikasiRepository.dart';
import '../features/notification/domain/usecases/addPresensiNotifikasiUsecase.dart';
import '../features/notification/domain/usecases/getNotifikasiUsecase.dart';
import '../features/notification/domain/usecases/markAllNotifikasiReadUsecase.dart';
import '../features/notification/presentation/providers/notifikasiProvider.dart';
import '../features/attendance/data/datasources/absensiRemoteDatasource.dart';
import '../features/attendance/data/repositories/absensiRepositoryImpl.dart';
import '../features/attendance/domain/repositories/absensiRepository.dart';
import '../features/attendance/domain/usecases/getAbsensiHistoryUsecase.dart';
import '../features/attendance/domain/usecases/getTodayStatusUsecase.dart';
import '../features/attendance/domain/usecases/checkInUsecase.dart';
import '../features/attendance/domain/usecases/checkOutUsecase.dart';
import '../features/attendance/domain/usecases/deleteAbsenUsecase.dart';
import '../features/attendance/presentation/providers/absensiProvider.dart';
import '../features/attendance/presentation/providers/presensiProvider.dart';
import '../features/attendance/presentation/providers/riwayatProvider.dart';
import '../features/leave/data/datasources/izinRemoteDatasource.dart';
import '../features/leave/data/repositories/izinRepositoryImpl.dart';
import '../features/leave/domain/repositories/izinRepository.dart';
import '../features/leave/domain/usecases/getIzinHistoryUsecase.dart';
import '../features/leave/domain/usecases/createIzinUsecase.dart';
import '../features/leave/presentation/providers/izinProvider.dart';
import '../features/statistics/presentation/providers/statistikProvider.dart';

final sl = GetIt.instance;

Future<void> initInjection(SharedPreferences prefs) async {
  // ─── Core Services ────────────────────────────────────────
  sl.registerLazySingleton<StorageService>(() => StorageService(prefs));
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<LokasiService>(() => LokasiService());

  // ─── Auth Feature ─────────────────────────────────────────

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<http.Client>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<StorageService>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<AuthRemoteDataSource>(),
      sl<AuthLocalDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetTrainingsUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetBatchesUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetGendersUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UploadPhotoUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl<AuthRepository>()));

  // Provider
  sl.registerFactory(
    () => AuthProvider(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      getTrainingsUseCase: sl<GetTrainingsUseCase>(),
      getBatchesUseCase: sl<GetBatchesUseCase>(),
      getGendersUseCase: sl<GetGendersUseCase>(),
      uploadPhotoUseCase: sl<UploadPhotoUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      verifyOtpUseCase: sl<VerifyOtpUseCase>(),
      resetPasswordUseCase: sl<ResetPasswordUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ─── Home Feature ─────────────────────────────────────────

  // Provider
  sl.registerFactory(() => HomeProvider());

  // ─── Profile Feature ──────────────────────────────────────

  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl<http.Client>()),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(
    () => UploadProfilePhotoUseCase(sl<ProfileRepository>()),
  );

  // Provider
  sl.registerFactory(
    () => ProfileProvider(
      getProfileUseCase: sl<GetProfileUseCase>(),
      updateProfileUseCase: sl<UpdateProfileUseCase>(),
      uploadProfilePhotoUseCase: sl<UploadProfilePhotoUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ─── Notification Feature ─────────────────────────────────

  // Data sources
  sl.registerLazySingleton<NotifikasiLocalDataSource>(
    () => NotifikasiLocalDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<NotifikasiRepository>(
    () => NotifikasiRepositoryImpl(sl<NotifikasiLocalDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(
    () => GetNotifikasiUseCase(sl<NotifikasiRepository>()),
  );
  sl.registerLazySingleton(
    () => AddPresensiNotifikasiUseCase(sl<NotifikasiRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkAllNotifikasiReadUseCase(sl<NotifikasiRepository>()),
  );

  // Provider
  sl.registerFactory(
    () => NotifikasiProvider(
      getNotifikasiUseCase: sl<GetNotifikasiUseCase>(),
      addPresensiNotifikasiUseCase: sl<AddPresensiNotifikasiUseCase>(),
      markAllNotifikasiReadUseCase: sl<MarkAllNotifikasiReadUseCase>(),
    ),
  );

  // ─── Attendance Feature ───────────────────────────────────

  // Data sources
  sl.registerLazySingleton<AbsensiRemoteDataSource>(
    () => AbsensiRemoteDataSourceImpl(sl<http.Client>()),
  );

  // Repository
  sl.registerLazySingleton<AbsensiRepository>(
    () => AbsensiRepositoryImpl(sl<AbsensiRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(
    () => GetAbsensiHistoryUseCase(sl<AbsensiRepository>()),
  );
  sl.registerLazySingleton(
    () => GetTodayStatusUseCase(sl<AbsensiRepository>()),
  );
  sl.registerLazySingleton(() => DeleteAbsenUseCase(sl<AbsensiRepository>()));
  sl.registerLazySingleton(() => CheckInUseCase(sl<AbsensiRepository>()));
  sl.registerLazySingleton(() => CheckOutUseCase(sl<AbsensiRepository>()));

  // Provider
  sl.registerFactory(
    () => AbsensiProvider(
      getHistoryUseCase: sl<GetAbsensiHistoryUseCase>(),
      getTodayStatusUseCase: sl<GetTodayStatusUseCase>(),
      deleteAbsenUseCase: sl<DeleteAbsenUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // Presensi Provider (check-in / check-out flow)
  sl.registerFactory(
    () => PresensiProvider(
      getTodayStatusUseCase: sl<GetTodayStatusUseCase>(),
      checkInUseCase: sl<CheckInUseCase>(),
      checkOutUseCase: sl<CheckOutUseCase>(),
      authRepository: sl<AuthRepository>(),
      lokasiService: sl<LokasiService>(),
    ),
  );

  // ─── Leave Feature ────────────────────────────────────────

  // Data sources
  sl.registerLazySingleton<IzinRemoteDataSource>(
    () => IzinRemoteDataSourceImpl(sl<http.Client>()),
  );

  // Repository
  sl.registerLazySingleton<IzinRepository>(
    () => IzinRepositoryImpl(sl<IzinRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetIzinHistoryUseCase(sl<IzinRepository>()));
  sl.registerLazySingleton(() => CreateIzinUseCase(sl<IzinRepository>()));

  // Provider
  sl.registerFactory(
    () => IzinProvider(
      getHistoryUseCase: sl<GetIzinHistoryUseCase>(),
      createIzinUseCase: sl<CreateIzinUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // Combined history provider (attendance + leave)
  sl.registerFactory(
    () => RiwayatProvider(
      getAbsensiHistoryUseCase: sl<GetAbsensiHistoryUseCase>(),
      getTodayStatusUseCase: sl<GetTodayStatusUseCase>(),
      getIzinHistoryUseCase: sl<GetIzinHistoryUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ─── Statistics Feature ────────────────────────────────────

  // Provider (reuses attendance usecase + auth repo)
  sl.registerFactory(
    () => StatistikProvider(
      getHistoryUseCase: sl<GetAbsensiHistoryUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
}
