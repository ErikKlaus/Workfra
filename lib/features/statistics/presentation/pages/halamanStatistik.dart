import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../providers/statistikProvider.dart';

class HalamanStatistik extends StatefulWidget {
  const HalamanStatistik({super.key});
  @override
  State<HalamanStatistik> createState() => _HalamanStatistikState();
}

class _HalamanStatistikState extends State<HalamanStatistik> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatistikProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatistikProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => provider.loadData(),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Title
              const SizedBox(height: 8),
              Text(
                'Statistik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),

              if (provider.isLoading)
                const _LoadingState()
              else if (provider.errorMessage != null)
                _ErrorState(
                  message: provider.errorMessage!,
                  onRetry: () => provider.loadData(),
                )
              else ...[
                // Summary card
                _SummaryCard(
                  totalHari: provider.totalHari,
                  hadir: provider.hadir,
                  telat: provider.telat,
                  absen: provider.absen,
                ),
                const SizedBox(height: 28),

                // Insight section
                Text(
                  'Insight Kehadiran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                _InsightGrid(
                  avgCheckIn: provider.avgCheckIn,
                  avgCheckOut: provider.avgCheckOut,
                  fastestCheckIn: provider.fastestCheckIn,
                  latestCheckOut: provider.latestCheckOut,
                ),
                const SizedBox(height: 28),

                // On-time percentage
                _OnTimeCard(percentage: provider.onTimePercentage),
                const SizedBox(height: 20),

                // Fun fact
                if (provider.funFact.isNotEmpty)
                  _FunFactCard(fact: provider.funFact),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int totalHari;
  final int hadir;
  final int telat;
  final int absen;

  const _SummaryCard({
    required this.totalHari,
    required this.hadir,
    required this.telat,
    required this.absen,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = 'Ringkasan Bulan Ini'.toUpperCase();

    return Container(
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
          Text(
            monthLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalHari',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Hari Kerja',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _SummaryBox(label: 'Hadir', value: '$hadir'),
              const SizedBox(width: 10),
              _SummaryBox(label: 'Telat', value: '$telat'),
              const SizedBox(width: 10),
              _SummaryBox(label: 'Absen', value: '$absen'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Insight Grid ─────────────────────────────────────────────

class _InsightGrid extends StatelessWidget {
  final String avgCheckIn;
  final String avgCheckOut;
  final String fastestCheckIn;
  final String latestCheckOut;

  const _InsightGrid({
    required this.avgCheckIn,
    required this.avgCheckOut,
    required this.fastestCheckIn,
    required this.latestCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                icon: Icons.login_rounded,
                iconColor: AppColors.primary,
                iconBgColor: const Color(0xFFE6F7FB),
                label: 'Rata-Rata\nCheck-In',
                value: avgCheckIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightCard(
                icon: Icons.logout_rounded,
                iconColor: AppColors.primary,
                iconBgColor: const Color(0xFFE6F7FB),
                label: 'Rata-Rata\nCheck-Out',
                value: avgCheckOut,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFF22C55E),
                iconBgColor: const Color(0xFFDCFCE7),
                label: 'In\nTercepat',
                value: fastestCheckIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightCard(
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFFEF4444),
                iconBgColor: const Color(0xFFFEE2E2),
                label: 'Out\nTerlama',
                value: latestCheckOut,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                    height: 1.3,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── On-Time Percentage Card ──────────────────────────────────

class _OnTimeCard extends StatelessWidget {
  final double percentage;
  const _OnTimeCard({required this.percentage});

  String get _subtitle {
    if (percentage >= 90) return 'Anda sangat disiplin bulan ini!';
    if (percentage >= 75) return 'Kehadiran Anda cukup baik.';
    if (percentage >= 50) return 'Masih bisa ditingkatkan lagi.';
    return 'Ayo tingkatkan kehadiran Anda!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-time Percentage',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _CircularPercentPainter(
                percentage: percentage,
                color: AppColors.primary,
                bgColor: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  '${percentage.round()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularPercentPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;

  _CircularPercentPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 6.0;

    // Background arc
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (percentage / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularPercentPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}

// ─── Fun Fact Card ────────────────────────────────────────────

class _FunFactCard extends StatelessWidget {
  final String fact;
  const _FunFactCard({required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FUN FACT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fact,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading & Error States ───────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ShimmerSkeleton(
        child: Column(
          children: [
            ShimmerBlock(
              height: 186,
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
            SizedBox(height: 24),
            ShimmerBlock(
              height: 18,
              width: 160,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            SizedBox(height: 14),
            ShimmerBlock(
              height: 88,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              margin: EdgeInsets.only(bottom: 12),
            ),
            ShimmerBlock(
              height: 88,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              margin: EdgeInsets.only(bottom: 12),
            ),
            ShimmerBlock(
              height: 88,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.errorColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
