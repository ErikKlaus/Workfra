/// Entity representing today's attendance status.
class AbsensiHariIni {
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final String? checkInTime;
  final String? checkOutTime;
  final DateTime? serverNow;
  final String status; // 'belum', 'hadir', 'late', 'absent', 'done'

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AbsensiHariIni &&
        other.hasCheckedIn == hasCheckedIn &&
        other.hasCheckedOut == hasCheckedOut &&
        other.checkInTime == checkInTime &&
        other.checkOutTime == checkOutTime &&
        other.serverNow == serverNow &&
        other.status == status;
  }

  @override
  int get hashCode {
    return hasCheckedIn.hashCode ^
        hasCheckedOut.hashCode ^
        checkInTime.hashCode ^
        checkOutTime.hashCode ^
        serverNow.hashCode ^
        status.hashCode;
  }
}
