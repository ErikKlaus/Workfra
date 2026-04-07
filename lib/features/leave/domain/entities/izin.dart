enum StatusIzin { approved, pending, rejected }

class Izin {
  final int? id;
  final String type;
  final DateTime date;
  final String reason;
  final StatusIzin status;
  final DateTime? processedAt;
  final String? rejectionReason;

  const Izin({
    this.id,
    required this.type,
    required this.date,
    required this.reason,
    required this.status,
    this.processedAt,
    this.rejectionReason,
  });

  String get statusLabel {
    switch (status) {
      case StatusIzin.approved:
        return 'Disetujui';
      case StatusIzin.pending:
        return 'Diproses';
      case StatusIzin.rejected:
        return 'Ditolak';
    }
  }
}
