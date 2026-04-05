import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({super.id, required super.name, required super.email, super.token, super.photoUrl});

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: token ?? json['token'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'photo_url': photoUrl};
  }
}
