class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'https://appabsensi.mobileprojp.com';

  // Auth endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String trainingsEndpoint = '/api/trainings';
  static String trainingDetailEndpoint(int id) => '/api/trainings/$id';
  static const String batchesEndpoint = '/api/batches';
  static const String gendersEndpoint = '/api/genders';
  static const String usersEndpoint = '/api/users';
  static const String deviceTokenEndpoint = '/api/device-token';
  static const String profileEndpoint = '/api/profile';
  static const String profilePhotoEndpoint = '/api/profile/photo';
  static const String forgotPasswordEndpoint = '/api/forgot-password';
  static const String verifyOtpEndpoint = '/api/verify-otp';
  static const String resetPasswordEndpoint = '/api/reset-password';

  // Attendance endpoints
  static const String absenEndpoint = '/api/absen';
  static const String absenHistoryEndpoint = '/api/absen/history';
  static const String absenStatsEndpoint = '/api/absen/stats';
  static const String absenTodayEndpoint = '/api/absen/today';
  static const String checkInEndpoint = '/api/absen/check-in';
  static const String checkOutEndpoint = '/api/absen/check-out';

  // Leave endpoints
  static const String izinEndpoint = '/api/izin';

  // Headers
  static const Map<String, String> acceptHeaders = {
    'Accept': 'application/json',
  };

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Backward compatible alias for existing code.
  static const Map<String, String> defaultHeaders = jsonHeaders;

  static Map<String, String> authAcceptHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> authJsonHeaders(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Backward compatible alias for existing code.
  static Map<String, String> authHeaders(String token) =>
      authJsonHeaders(token);
}
