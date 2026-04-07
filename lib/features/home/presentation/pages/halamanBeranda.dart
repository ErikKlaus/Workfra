import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/profilePhotoHelper.dart';
import '../../../../core/utils/transisiHalaman.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../../../auth/presentation/providers/authProvider.dart';
import '../../../notification/presentation/pages/halamanNotifikasi.dart';
import '../../../notification/presentation/providers/notifikasiProvider.dart';
import '../../../profile/presentation/pages/halamanProfil.dart';
import '../../../profile/presentation/providers/profileProvider.dart';
import '../../../attendance/presentation/pages/halamanRiwayat.dart';
import '../../../attendance/presentation/providers/presensiProvider.dart';
import '../../../attendance/presentation/providers/riwayatProvider.dart';
import '../../../leave/presentation/pages/halamanIzin.dart';
import '../../../leave/presentation/widgets/kartuIzin.dart';
import '../../../statistics/presentation/pages/halamanStatistik.dart';
import '../providers/berandaProvider.dart';
import '../widgets/navigasiBawah.dart';
import '../widgets/checkInBar.dart' show CheckInCard;
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
      context.read<ProfileProvider>().loadProfile();
      context.read<PresensiProvider>().loadTodayStatus();
      context.read<RiwayatProvider>().combineData();
      context.read<NotifikasiProvider>().loadNotifikasi();
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _refreshAfterPresensi() {
    context.read<PresensiProvider>().loadTodayStatus();
    context.read<RiwayatProvider>().combineData();
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _BerandaContent(
          onLihatSemua: () => _onNavTap(1),
          onPresensiReturn: _refreshAfterPresensi,
        );
      case 1:
        return const HalamanRiwayat();
      case 2:
        return const HalamanIzin();
      case 3:
        return const HalamanStatistik();
      default:
        return const _PlaceholderTab(index: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
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
  static const _labels = ['Home', 'Riwayat', 'Izin', 'Statistik'];

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
  final VoidCallback onLihatSemua;
  final VoidCallback? onPresensiReturn;
  const _BerandaContent({required this.onLihatSemua, this.onPresensiReturn});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final presensiProvider = context.read<PresensiProvider>();
        final riwayatProvider = context.read<RiwayatProvider>();
        await presensiProvider.loadTodayStatus();
        await riwayatProvider.combineData();
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const _AppBarSection(),
          const SizedBox(height: 20),
          const _PresensiSection(),
          const SizedBox(height: 16),
          CheckInCard(onReturn: onPresensiReturn),
          const SizedBox(height: 24),
          _RiwayatSection(onLihatSemua: onLihatSemua),
          const SizedBox(height: 30),
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
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final profile = profileProvider.profile;
    final userName = profile?.name ?? authProvider.user?.name ?? 'User';
    final photoUrl = profile?.photoUrl;
    final profileImage = ProfilePhotoHelper.toImageProvider(photoUrl);
    final hasUnread = context.watch<NotifikasiProvider>().hasUnread;
    const ink900 = Color(0xFF111827);

    if (profileProvider.isLoading && profile == null) {
      return const _AppBarShimmer();
    }

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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    buildFadeRoute(const HalamanNotifikasi()),
                  );
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: ink900,
                  size: 24,
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(context, buildFadeRoute(const HalamanProfil())).then(
              (_) {
                profileProvider.loadProfile();
              },
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE6F7FB),
              border: Border.all(color: const Color(0xFFBEEAF3), width: 1),
              image: profileImage != null
                  ? DecorationImage(image: profileImage, fit: BoxFit.cover)
                  : null,
            ),
            child: profileImage == null
                ? const ClipOval(
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  )
                : null,
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
    final presensiProvider = context.watch<PresensiProvider>();
    final todayStatus = presensiProvider.todayStatus;
    final now = DateTime.now();

    if (presensiProvider.isLoadingData &&
        !presensiProvider.hasCachedTodayStatus) {
      return const ShimmerSkeleton(
        child: ShimmerBlock(
          height: 168,
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
      );
    }

    return KartuPresensi(
      lokasi: 'PPKD Jakarta Pusat',
      tanggal: now,
      checkIn: _displayValue(todayStatus.checkInTime),
      checkOut: _displayValue(todayStatus.checkOutTime),
      statusLabel: _statusLabel(todayStatus.status),
    );
  }

  String _displayValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '-';
    }
    return normalized;
  }

  String _statusLabel(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'late':
      case 'telat':
        return 'Telat';
      case 'absent':
      case 'absen':
        return 'Absen';
      case 'on_time':
      case 'tepat_waktu':
      case 'hadir':
      case 'done':
      case 'masuk':
      case 'pulang':
      case 'present':
      case 'check_in':
      case 'check_out':
        return 'Hadir';
      case 'izin':
      case 'leave':
      case 'permission':
      case 'cuti':
      case 'sakit':
        return 'Izin';
      default:
        return '-';
    }
  }
}

class _RiwayatSection extends StatelessWidget {
  final VoidCallback onLihatSemua;
  const _RiwayatSection({required this.onLihatSemua});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RiwayatHeader(onLihatSemua: onLihatSemua),
        const SizedBox(height: 12),
        const _RiwayatList(),
      ],
    );
  }
}

class _RiwayatHeader extends StatelessWidget {
  final VoidCallback onLihatSemua;
  const _RiwayatHeader({required this.onLihatSemua});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat Terbaru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        GestureDetector(
          onTap: onLihatSemua,
          child: Text(
            'Lihat Semua',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
    return Consumer<RiwayatProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.combinedData.isEmpty) {
          return const ShimmerSkeleton(
            child: Column(
              children: [
                ShimmerBlock(
                  height: 90,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                  margin: EdgeInsets.only(bottom: 12),
                ),
                ShimmerBlock(
                  height: 90,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                  margin: EdgeInsets.only(bottom: 12),
                ),
                ShimmerBlock(
                  height: 90,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
              ],
            ),
          );
        }

        if (provider.errorMessage != null && provider.combinedData.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          );
        }

        if (provider.combinedData.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Belum ada riwayat presensi dan izin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          );
        }

        final previewList = provider.combinedData.take(3).toList();
        return Column(
          children: previewList
              .map(
                (item) => item.jenis == JenisRiwayatGabungan.presensi
                    ? KartuRiwayat(riwayat: item.presensi!)
                    : KartuIzin(izin: item.izin!),
              )
              .toList(),
        );
      },
    );
  }
}

class _AppBarShimmer extends StatelessWidget {
  const _AppBarShimmer();

  @override
  Widget build(BuildContext context) {
    return const ShimmerSkeleton(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(
                  height: 14,
                  width: 120,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 8),
                ShimmerBlock(
                  height: 20,
                  width: 170,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          ShimmerBlock(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          SizedBox(width: 8),
          ShimmerBlock(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ],
      ),
    );
  }
}
