import '../../../auth/domain/entities/user.dart';
import '../../../../core/utils/profilePhotoHelper.dart';

class ProfileModel extends User {
  const ProfileModel({
    super.id,
    required super.name,
    required super.email,
    super.token,
    super.photoUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return ProfileModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: token ?? json['token'] as String?,
      photoUrl: ProfilePhotoHelper.extractPhotoSource(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'photo_url': photoUrl};
  }
}
