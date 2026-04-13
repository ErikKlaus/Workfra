import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/izin.dart';

class KartuIzin extends StatelessWidget {
  final Izin izin;
  const KartuIzin({super.key, required this.izin});

  String _typeLabel(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'sakit':
        return tr(context, 'leave_type_sick');
      case 'izin':
        return tr(context, 'leave_type_permission');
      case 'lainnya':
      case 'other':
        return tr(context, 'leave_type_other');
      default:
        return type;
    }
  }

  String _statusLabel(BuildContext context, StatusIzin status) {
    switch (status) {
      case StatusIzin.approved:
        return tr(context, 'status_approved');
      case StatusIzin.pending:
        return tr(context, 'status_pending');
      case StatusIzin.rejected:
        return tr(context, 'status_rejected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final statusColor = colorScheme.onSurface.withValues(alpha: 0.7);
    final IconData typeIcon;
    final iconBgColor = colorScheme.onSurface.withValues(alpha: 0.08);

    switch (izin.type.toLowerCase()) {
      case 'sakit':
        typeIcon = Icons.medical_services_outlined;
        break;
      case 'izin':
        typeIcon = Icons.assignment_outlined;
        break;
      default:
        typeIcon = Icons.description_outlined;
        break;
    }

    final dateFormat = DateFormat('dd MMM yyyy', context.intlLocale);

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
            child: Icon(typeIcon, size: 20, color: statusColor),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(context, izin.type),
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
                    tr(
                      context,
                      'processed_at',
                      params: {
                        'datetime': DateFormat(
                          'dd MMM, HH:mm',
                          context.intlLocale,
                        ).format(izin.processedAt!),
                      },
                    ),
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
                      color: statusColor,
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
              _statusLabel(context, izin.status),
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
