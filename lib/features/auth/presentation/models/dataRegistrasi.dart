class RegisterIdentityData {
  final String name;
  final String email;
  final int trainingId;
  final int batchId;
  final int genderId;

  const RegisterIdentityData({
    required this.name,
    required this.email,
    required this.trainingId,
    required this.batchId,
    required this.genderId,
  });

  PendingRegistrationData withPassword(String password) {
    return PendingRegistrationData(
      name: name,
      email: email,
      password: password,
      trainingId: trainingId,
      batchId: batchId,
      genderId: genderId,
    );
  }
}

class PendingRegistrationData {
  final String name;
  final String email;
  final String password;
  final int trainingId;
  final int batchId;
  final int genderId;

  const PendingRegistrationData({
    required this.name,
    required this.email,
    required this.password,
    required this.trainingId,
    required this.batchId,
    required this.genderId,
  });

  RegisterIdentityData get identity {
    return RegisterIdentityData(
      name: name,
      email: email,
      trainingId: trainingId,
      batchId: batchId,
      genderId: genderId,
    );
  }
}
