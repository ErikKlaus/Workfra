import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../domain/entities/izin.dart';

class KartuIzin extends StatelessWidget {
  final Izin izin;
  const KartuIzin({super.key, required this.izin});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const approvedColor = Color(0xFF22C55E);
    final pendingColor = colorScheme.onSurface.withValues(alpha: 0.7);
    const rejectedColor = Color(0xFFEF4444);

    final Color statusColor;
    final IconData typeIcon;
    final Color iconBgColor;

    switch (izin.status) {
      case StatusIzin.approved:
        statusColor = approvedColor;
        break;
      case StatusIzin.rejected:
        statusColor = rejectedColor;
        break;
      case StatusIzin.pending:
        statusColor = pendingColor;
        break;
    }

    switch (izin.type.toLowerCase()) {
      case 'sakit':
        typeIcon = Icons.medical_services_outlined;
        iconBgColor = const Color(0xFFE6F7FB);
        break;
      case 'izin':
        typeIcon = Icons.assignment_outlined;
        iconBgColor = const Color(0xFFEDE9FE);
        break;
      default:
        typeIcon = Icons.description_outlined;
        iconBgColor = const Color(0xFFFEE2E2);
        break;
    }

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

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
          // Type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  izin.type,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(izin.date)} • ${izin.reason}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                if (izin.processedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Diproses: ${DateFormat('dd MMM, HH:mm', 'id_ID').format(izin.processedAt!)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
                if (izin.status == StatusIzin.rejected &&
                    izin.rejectionReason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    izin.rejectionReason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: rejectedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              izin.statusLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
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
