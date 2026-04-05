class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'https://appabsensi.mobileprojp.com';

  // Auth endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String trainingsEndpoint = '/api/trainings';
  static const String batchesEndpoint = '/api/batches';
  static const String gendersEndpoint = '/api/genders';
  static const String profilePhotoEndpoint = '/api/profile/photo';
  static const String forgotPasswordEndpoint = '/api/forgot-password';
  static const String verifyOtpEndpoint = '/api/verify-otp';
  static const String resetPasswordEndpoint = '/api/reset-password';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
