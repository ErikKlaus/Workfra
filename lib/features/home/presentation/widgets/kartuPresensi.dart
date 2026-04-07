import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/temaAplikasi.dart';

class KartuPresensi extends StatelessWidget {
  final String lokasi;
  final DateTime tanggal;
  final String? checkIn;
  final String? checkOut;
  final String? statusLabel;

  const KartuPresensi({
    super.key,
    required this.lokasi,
    required this.tanggal,
    this.checkIn,
    this.checkOut,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0FA9C4), Color(0xFF0C8FA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.textOnPrimary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lokasi,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textOnPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              dateFormat.format(tanggal),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimeColumn(
                  label: 'CHECK IN',
                  value: _displayValue(checkIn),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              Expanded(
                child: _TimeColumn(
                  label: 'CHECK OUT',
                  value: _displayValue(checkOut),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _TimeColumn extends StatelessWidget {
  final String label;
  final String value;

  const _TimeColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
