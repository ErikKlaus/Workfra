import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/layananPenyimpanan.dart';
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
import '../features/home/data/datasources/berandaRemoteDatasource.dart';
import '../features/home/data/repositories/berandaRepositoryImpl.dart';
import '../features/home/domain/repositories/berandaRepository.dart';
import '../features/home/domain/usecases/getRiwayatUsecase.dart';
import '../features/home/presentation/providers/berandaProvider.dart';

final sl = GetIt.instance;

Future<void> initInjection(SharedPreferences prefs) async {
  // ─── Core Services ────────────────────────────────────────
  sl.registerLazySingleton<StorageService>(() => StorageService(prefs));
  sl.registerLazySingleton<http.Client>(() => http.Client());

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

  // Data sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetRiwayatUseCase(sl<HomeRepository>()));

  // Provider
  sl.registerFactory(
    () => HomeProvider(getRiwayatUseCase: sl<GetRiwayatUseCase>()),
  );
}
