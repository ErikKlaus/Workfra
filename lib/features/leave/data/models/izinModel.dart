import '../../domain/entities/izin.dart';

class IzinModel extends Izin {
  const IzinModel({
    super.id,
    required super.type,
    required super.date,
    required super.reason,
    required super.status,
    super.processedAt,
    super.rejectionReason,
  });

  factory IzinModel.fromJson(Map<String, dynamic> json) {
    return IzinModel(
      id: json['id'] as int?,
      type: json['type'] as String? ?? json['jenis'] as String? ?? '',
      date: DateTime.parse(json['date'] as String? ?? json['tanggal'] as String? ?? DateTime.now().toIso8601String()),
      reason: json['reason'] as String? ?? json['alasan'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String? ??
          json['alasan_ditolak'] as String?,
    );
  }

  static StatusIzin _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return StatusIzin.approved;
      case 'rejected':
      case 'ditolak':
        return StatusIzin.rejected;
      case 'pending':
      case 'diproses':
      default:
        return StatusIzin.pending;
    }
  }
}
