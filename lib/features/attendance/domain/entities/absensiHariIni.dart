/// Entity representing today's attendance status.
class AbsensiHariIni {
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final String? checkInTime;
  final String? checkOutTime;
  final DateTime? serverNow;
  final String status; // 'belum', 'on_time', 'late', 'done'

  const AbsensiHariIni({
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    this.checkInTime,
    this.checkOutTime,
    this.serverNow,
    required this.status,
  });

  /// Default state: no attendance yet today.
  static const empty = AbsensiHariIni(
    hasCheckedIn: false,
    hasCheckedOut: false,
    status: 'belum',
  );

  bool get isComplete => hasCheckedIn && hasCheckedOut;

  AbsensiHariIni copyWith({
    bool? hasCheckedIn,
    bool? hasCheckedOut,
    String? checkInTime,
    String? checkOutTime,
    DateTime? serverNow,
    String? status,
  }) {
    return AbsensiHariIni(
      hasCheckedIn: hasCheckedIn ?? this.hasCheckedIn,
      hasCheckedOut: hasCheckedOut ?? this.hasCheckedOut,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      serverNow: serverNow ?? this.serverNow,
      status: status ?? this.status,
    );
  }
}
