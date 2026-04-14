import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tugas_16_flutter/core/services/layananPenyimpanan.dart';
import 'package:tugas_16_flutter/features/auth/domain/entities/jenisKelamin.dart';
import 'package:tugas_16_flutter/features/auth/domain/entities/opsiDropdown.dart';
import 'package:tugas_16_flutter/features/auth/domain/entities/user.dart';
import 'package:tugas_16_flutter/features/auth/domain/repositories/authRepository.dart';
import 'package:tugas_16_flutter/features/profile/domain/repositories/profileRepository.dart';
import 'package:tugas_16_flutter/features/profile/domain/usecases/getProfileUsecase.dart';
import 'package:tugas_16_flutter/features/profile/domain/usecases/updateProfileUsecase.dart';
import 'package:tugas_16_flutter/features/profile/domain/usecases/uploadProfilePhotoUsecase.dart';
import 'package:tugas_16_flutter/features/profile/presentation/providers/profileProvider.dart';

class FakeProfileRepository implements ProfileRepository {
  User getProfileResult = const User(
    id: 1,
    name: 'Initial User',
    email: 'initial@example.com',
    photoUrl: 'https://cdn.example.com/old-photo.jpg',
  );

  User updateProfileResult = const User(
    id: 1,
    name: 'Updated User',
    email: 'updated@example.com',
    photoUrl: null,
  );

  @override
  Future<User> getProfile({required String token}) async {
    return getProfileResult;
  }

  @override
  Future<User> updateProfile({
    required String token,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    return updateProfileResult;
  }

  @override
  Future<void> uploadPhoto({required String token, required String filePath}) {
    return Future.value();
  }
}

class FakeAuthRepository implements AuthRepository {
  String? token;

  @override
  Future<String?> getToken() async => token;

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

  late FakeProfileRepository fakeProfileRepo;
  late FakeAuthRepository fakeAuthRepo;
  late StorageService storageService;
  late ProfileProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    fakeProfileRepo = FakeProfileRepository();
    fakeAuthRepo = FakeAuthRepository()..token = 'valid_token';
    storageService = StorageService(prefs);

    provider = ProfileProvider(
      getProfileUseCase: GetProfileUseCase(fakeProfileRepo),
      updateProfileUseCase: UpdateProfileUseCase(fakeProfileRepo),
      uploadProfilePhotoUseCase: UploadProfilePhotoUseCase(fakeProfileRepo),
      authRepository: fakeAuthRepo,
      storageService: storageService,
    );
  });

  group('ProfileProvider.updateProfile', () {
    test(
      'preserves existing photo URL when update response omits photo',
      () async {
        await provider.loadProfile(forceRefresh: true);
        expect(
          provider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );

        fakeProfileRepo.updateProfileResult = const User(
          id: 1,
          name: 'New Name',
          email: 'new@example.com',
          photoUrl: null,
        );

        final success = await provider.updateProfile(
          name: 'New Name',
          email: 'new@example.com',
        );

        expect(success, isTrue);
        expect(provider.profile?.name, 'New Name');
        expect(provider.profile?.email, 'new@example.com');
        expect(
          provider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );
      },
    );

    test(
      'preserves previous photo even when update response includes a different photo',
      () async {
        await provider.loadProfile(forceRefresh: true);

        fakeProfileRepo.updateProfileResult = const User(
          id: 1,
          name: 'New Name',
          email: 'new@example.com',
          photoUrl: 'https://cdn.example.com/new-photo.jpg',
        );

        final success = await provider.updateProfile(
          name: 'New Name',
          email: 'new@example.com',
        );

        expect(success, isTrue);
        // Photo should NOT change during a name/email update — only uploadPhoto
        // can change the photo. The previous photo URL must be preserved.
        expect(
          provider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );
      },
    );

    test(
      'preserves existing photo URL when update response has empty photo',
      () async {
        await provider.loadProfile(forceRefresh: true);

        fakeProfileRepo.updateProfileResult = const User(
          id: 1,
          name: 'New Name',
          email: 'new@example.com',
          photoUrl: '   ',
        );

        final success = await provider.updateProfile(
          name: 'New Name',
          email: 'new@example.com',
        );

        expect(success, isTrue);
        expect(
          provider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );
      },
    );

    test(
      'preserves existing photo URL when update response has "null" string photo',
      () async {
        await provider.loadProfile(forceRefresh: true);

        fakeProfileRepo.updateProfileResult = const User(
          id: 1,
          name: 'New Name',
          email: 'new@example.com',
          photoUrl: 'null',
        );

        final success = await provider.updateProfile(
          name: 'New Name',
          email: 'new@example.com',
        );

        expect(success, isTrue);
        expect(
          provider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );
      },
    );

    test('keeps photo URL null when no previous photo exists', () async {
      fakeProfileRepo.getProfileResult = const User(
        id: 1,
        name: 'Initial User',
        email: 'initial@example.com',
        photoUrl: null,
      );

      await provider.loadProfile(forceRefresh: true);
      expect(provider.profile?.photoUrl, isNull);

      fakeProfileRepo.updateProfileResult = const User(
        id: 1,
        name: 'New Name',
        email: 'new@example.com',
        photoUrl: null,
      );

      final success = await provider.updateProfile(
        name: 'New Name',
        email: 'new@example.com',
      );

      expect(success, isTrue);
      expect(provider.profile?.photoUrl, isNull);
    });

    test(
      'preserves cached photo when update is called in a fresh provider session',
      () async {
        await provider.loadProfile(forceRefresh: true);

        final freshProvider = ProfileProvider(
          getProfileUseCase: GetProfileUseCase(fakeProfileRepo),
          updateProfileUseCase: UpdateProfileUseCase(fakeProfileRepo),
          uploadProfilePhotoUseCase: UploadProfilePhotoUseCase(fakeProfileRepo),
          authRepository: fakeAuthRepo,
          storageService: storageService,
        );

        fakeProfileRepo.updateProfileResult = const User(
          id: 1,
          name: 'Fresh Session Name',
          email: 'fresh@example.com',
          photoUrl: null,
        );

        final success = await freshProvider.updateProfile(
          name: 'Fresh Session Name',
          email: 'fresh@example.com',
        );

        expect(success, isTrue);
        expect(
          freshProvider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );
      },
    );

    test('preserves base64 photo when update response omits photo', () async {
      const base64Photo =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAA';

      fakeProfileRepo.getProfileResult = const User(
        id: 1,
        name: 'Base64 User',
        email: 'base64@example.com',
        photoUrl: base64Photo,
      );

      await provider.loadProfile(forceRefresh: true);
      expect(provider.profile?.photoUrl, base64Photo);

      fakeProfileRepo.updateProfileResult = const User(
        id: 1,
        name: 'Updated Name',
        email: 'base64@example.com',
        photoUrl: null,
      );

      final success = await provider.updateProfile(
        name: 'Updated Name',
        email: 'base64@example.com',
      );

      expect(success, isTrue);
      expect(provider.profile?.name, 'Updated Name');
      expect(provider.profile?.photoUrl, base64Photo);
    });
  });

  group('ProfileProvider.loadProfile', () {
    test(
      'preserves cached photo when get profile response omits photo',
      () async {
        await provider.loadProfile(forceRefresh: true);

        fakeProfileRepo.getProfileResult = const User(
          id: 1,
          name: 'Updated Name',
          email: 'updated@example.com',
          photoUrl: null,
        );

        final freshProvider = ProfileProvider(
          getProfileUseCase: GetProfileUseCase(fakeProfileRepo),
          updateProfileUseCase: UpdateProfileUseCase(fakeProfileRepo),
          uploadProfilePhotoUseCase: UploadProfilePhotoUseCase(fakeProfileRepo),
          authRepository: fakeAuthRepo,
          storageService: storageService,
        );

        await freshProvider.loadProfile(forceRefresh: true);

        expect(
          freshProvider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );
      },
    );

    test(
      'keeps cached base64 photo when API returns non-base64 photo URL',
      () async {
        const base64Photo =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAA';

        fakeProfileRepo.getProfileResult = const User(
          id: 1,
          name: 'Initial User',
          email: 'initial@example.com',
          photoUrl: base64Photo,
        );
        await provider.loadProfile(forceRefresh: true);
        expect(provider.profile?.photoUrl, base64Photo);

        fakeProfileRepo.getProfileResult = const User(
          id: 1,
          name: 'Updated User',
          email: 'updated@example.com',
          photoUrl: 'https://cdn.example.com/possibly-stale-path.jpg',
        );

        await provider.loadProfile(forceRefresh: true);

        expect(provider.profile?.photoUrl, base64Photo);
      },
    );

    test(
      'falls back to cached photo when API returns localhost photo URL',
      () async {
        fakeProfileRepo.getProfileResult = const User(
          id: 1,
          name: 'Initial User',
          email: 'initial@example.com',
          photoUrl: 'https://cdn.example.com/old-photo.jpg',
        );
        await provider.loadProfile(forceRefresh: true);

        fakeProfileRepo.getProfileResult = const User(
          id: 1,
          name: 'Updated User',
          email: 'updated@example.com',
          photoUrl: 'http://127.0.0.1/storage/avatar.jpg',
        );

        await provider.loadProfile(forceRefresh: true);

        expect(
          provider.profile?.photoUrl,
          'https://cdn.example.com/old-photo.jpg',
        );
      },
    );
  });
}
