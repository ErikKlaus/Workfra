import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/transisiHalaman.dart';
import '../../../attendance/presentation/pages/halamanPresensi.dart';
import '../../../attendance/presentation/providers/presensiProvider.dart';
import '../../../profile/presentation/providers/profileProvider.dart';
import '../../../attendance/domain/entities/absensiHariIni.dart';

/// Action card showing today's check-in status with a button.
/// Placed inline inside the home content (below attendance summary).
class CheckInCard extends StatelessWidget {
  final VoidCallback? onReturn;
  const CheckInCard({super.key, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Selector<PresensiProvider, AbsensiHariIni>(
      selector: (context, provider) => provider.todayStatus,
      builder: (context, status, _) {
        final checkIn = _displayValue(status.checkInTime);
        final checkOut = _displayValue(status.checkOutTime);

        // Determine state
        String buttonLabel;
        Color buttonColor;
        IconData statusIcon;
        Color statusIconBg;
        bool enabled;

        if (status.isComplete) {
          buttonLabel = 'Selesai';
          buttonColor = colorScheme.onSurface.withValues(alpha: 0.55);
          statusIcon = Icons.check_circle_outline;
          statusIconBg = isDark
              ? colorScheme.surface.withValues(alpha: 0.8)
              : const Color(0xFFE5E7EB);
          enabled = false;
        } else if (status.hasCheckedIn) {
          buttonLabel = 'Check Out';
          buttonColor = const Color(0xFFEF4444);
          statusIcon = Icons.access_time_filled;
          statusIconBg = const Color(0xFFDCFCE7);
          enabled = true;
        } else {
          buttonLabel = 'Check In';
          buttonColor = AppColors.primary;
          statusIcon = Icons.access_time_filled;
          statusIconBg = const Color(0xFFE6F7FB);
          enabled = true;
        }

        return Container(
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
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: status.isComplete
                      ? colorScheme.onSurface.withValues(alpha: 0.7)
                      : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Time text
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _TimePill(label: 'Masuk', value: checkIn),
                    _TimePill(label: 'Pulang', value: checkOut),
                  ],
                ),
              ),

              // Action button
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: enabled
                      ? () async {
                          final presensiProvider = context.read<PresensiProvider>();
                          final profileProvider = context.read<ProfileProvider>();

                          // Prefetch without awaiting so navigation is instant
                          presensiProvider.prefetchPresensiData();
                          profileProvider.loadProfile();

                          final result = await Navigator.push<bool>(
                            context,
                            buildFadeRoute(const HalamanPresensi()),
                          );
                          if (!context.mounted) return;
                          if (result == true) {
                            onReturn?.call();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: buttonColor.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    minimumSize: const Size(0, 40),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _displayValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '-';
    }
    return normalized;
  }
}

class _TimePill extends StatelessWidget {
  final String label;
  final String value;

  const _TimePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.55 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
