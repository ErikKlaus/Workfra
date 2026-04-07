class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'https://appabsensi.mobileprojp.com';

  // Auth endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String trainingsEndpoint = '/api/trainings';
  static const String batchesEndpoint = '/api/batches';
  static const String gendersEndpoint = '/api/genders';
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
