import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../auth/presentation/providers/authProvider.dart';
import '../../domain/entities/riwayat.dart';
import '../providers/berandaProvider.dart';
import '../widgets/navigasiBawah.dart';
import '../widgets/kartuPresensi.dart';
import '../widgets/kartuRiwayat.dart';

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key});
  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadRiwayat();
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _currentNavIndex == 0
            ? const _BerandaContent()
            : _PlaceholderTab(index: _currentNavIndex),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final int index;
  const _PlaceholderTab({required this.index});
  static const _labels = ['Home', 'Riwayat', '', 'Izin', 'Statistik'];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Halaman ${_labels[index]}\n(Segera Hadir)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: AppColors.secondaryText),
      ),
    );
  }
}

class _BerandaContent extends StatelessWidget {
  const _BerandaContent();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await context.read<HomeProvider>().loadRiwayat();
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: const [
          _AppBarSection(),
          SizedBox(height: 20),
          _PresensiSection(),
          SizedBox(height: 30),
          _RiwayatSection(),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _AppBarSection extends StatelessWidget {
  const _AppBarSection();

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'User';
    const ink900 = Color(0xFF111827);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homeProvider.getGreeting(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: ink900,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final authProvider = context.read<AuthProvider>();
            await authProvider.logout();
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE6F7FB),
              border: Border.all(color: const Color(0xFFBEEAF3), width: 1),
            ),
            child: const ClipOval(
              child: Icon(Icons.person, color: AppColors.primary, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresensiSection extends StatelessWidget {
  const _PresensiSection();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return KartuPresensi(
      lokasi: 'PPKD Jakarta Pusat',
      tanggal: now,
      checkIn:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      checkOut: null,
    );
  }
}

class _RiwayatSection extends StatelessWidget {
  const _RiwayatSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [_RiwayatHeader(), SizedBox(height: 12), _RiwayatList()],
    );
  }
}

class _RiwayatHeader extends StatelessWidget {
  const _RiwayatHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat Terbaru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'Lihat Semua',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RiwayatList extends StatelessWidget {
  const _RiwayatList();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeProvider, List<Riwayat>>(
      selector: (_, provider) => provider.riwayatTerbaru,
      builder: (context, riwayatList, _) {
        if (riwayatList.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Belum ada riwayat presensi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          );
        }
        return Column(
          children: riwayatList
              .take(3)
              .map((riwayat) => KartuRiwayat(riwayat: riwayat))
              .toList(),
        );
      },
    );
  }
}
