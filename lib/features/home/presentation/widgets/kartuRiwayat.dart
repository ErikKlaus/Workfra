import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/riwayat.dart';

class KartuRiwayat extends StatelessWidget {
  final Riwayat riwayat;
  const KartuRiwayat({super.key, required this.riwayat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    const onTimeColor = Color(0xFF22C55E);
    const lateColor = Color(0xFFF59E0B);
    const absentColor = Color(0xFFEF4444);
    final izinColor = colorScheme.onSurface.withValues(alpha: 0.7);
    const unknownColor = Color(0xFF9CA3AF);
    final textPrimary = colorScheme.onSurface;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (riwayat.isIzin) {
      statusColor = izinColor;
      statusLabel = 'Izin';
      statusIcon = Icons.event_note_rounded;
    } else if (riwayat.isAbsent) {
      statusColor = absentColor;
      statusLabel = 'Absen';
      statusIcon = Icons.error_outline_rounded;
    } else if (riwayat.isTelat) {
      statusColor = lateColor;
      statusLabel = 'Telat';
      statusIcon = Icons.warning_amber_rounded;
    } else if (riwayat.isOnTime) {
      statusColor = onTimeColor;
      statusLabel = 'Hadir';
      statusIcon = Icons.access_time;
    } else {
      statusColor = unknownColor;
      statusLabel = '-';
      statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(riwayat.tanggal),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                if (riwayat.isAbsent)
                  Text(
                    'Tanpa Keterangan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w400,
                    ),
                  )
                else ...[
                  Text(
                    'Masuk: ${riwayat.jamMasuk ?? '-'} • Pulang: ${riwayat.jamKeluar ?? '-'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
