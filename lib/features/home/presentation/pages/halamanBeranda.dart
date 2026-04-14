import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/attendance_utils.dart';
import '../../../../core/utils/profilePhotoHelper.dart';
import '../../../../core/utils/screen_perf_profiler.dart';
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

class _HalamanBerandaState extends State<HalamanBeranda>
    with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  late final PageController _pageController;

  DateTime? _lastBackPressedAt;

  static const Duration _exitBackPressInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    ScreenPerfProfiler.trackFirstFrame('home');
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentNavIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
      context.read<PresensiProvider>().loadTodayStatus();
      context.read<RiwayatProvider>().combineData();
      context.read<NotifikasiProvider>().loadNotifikasi(
        localeCode: Localizations.localeOf(context).languageCode,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      return;
    }

    setState(() {
      _currentNavIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    if (!mounted || index == _currentNavIndex) {
      return;
    }
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _refreshAfterPresensi() {
    // Silent background refresh — UI tetap menampilkan data terakhir
    context.read<PresensiProvider>().loadTodayStatus(forceRefresh: true);
    context.read<RiwayatProvider>().silentRefresh();
  }

  void _handleBackPressed() {
    if (_currentNavIndex != 0) {
      _onNavTap(0);
      return;
    }

    final now = DateTime.now();
    final shouldExit =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) <= _exitBackPressInterval;

    if (shouldExit) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(tr(context, 'app_exit_hint')),
        behavior: SnackBarBehavior.floating,
        duration: _exitBackPressInterval,
      ),
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      allowImplicitScrolling: true,
      physics: const _FastSwipePagePhysics(parent: BouncingScrollPhysics()),
      children: [
        _BerandaContent(
          onLihatSemua: () => _onNavTap(1),
          onPresensiReturn: _refreshAfterPresensi,
        ),
        const HalamanRiwayat(),
        const HalamanIzin(),
        const HalamanStatistik(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenPerfProfiler.markBuild('home');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(child: _buildBody()),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _FastSwipePagePhysics extends PageScrollPhysics {
  const _FastSwipePagePhysics({super.parent});

  @override
  _FastSwipePagePhysics applyTo(ScrollPhysics? ancestor) {
    return _FastSwipePagePhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingDistance => 5;

  @override
  double get minFlingVelocity => 50;
}

class _BerandaContent extends StatelessWidget {
  final VoidCallback onLihatSemua;
  final VoidCallback? onPresensiReturn;
  const _BerandaContent({required this.onLihatSemua, this.onPresensiReturn});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => Future.wait([
        context.read<PresensiProvider>().loadTodayStatus(),
        context.read<RiwayatProvider>().combineData(),
      ]),
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
    final greetingKey = context.select((HomeProvider h) => h.getGreetingKey());
    final greeting = tr(context, greetingKey);
    final colorScheme = Theme.of(context).colorScheme;

    final profile = context.select((ProfileProvider p) => p.profile);
    final isProfileLoading = context.select((ProfileProvider p) => p.isLoading);
    final authUserName = context.select((AuthProvider a) => a.user?.name);
    final userName =
        profile?.name ?? authUserName ?? tr(context, 'user_default_name');

    final photoUrl = profile?.photoUrl;
    final profileImage = ProfilePhotoHelper.toImageProvider(photoUrl);

    final hasUnread = context.select((NotifikasiProvider n) => n.hasUnread);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isProfileLoading && profile == null) {
      return const _AppBarShimmer();
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: colorScheme.onSurface,
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
                if (context.mounted) {
                  context.read<ProfileProvider>().loadProfile();
                }
              },
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? colorScheme.surface.withValues(alpha: 0.9)
                  : const Color(0xFFE6F7FB),
              border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.45)
                    : const Color(0xFFBEEAF3),
                width: 1,
              ),
            ),
            child: profileImage == null
                ? const ClipOval(
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  )
                : ClipOval(
                    child: Image(
                      image: profileImage,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                    ),
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
    final (isLoadingData, hasCachedTodayStatus, todayStatus) = context.select(
      (PresensiProvider p) =>
          (p.isLoadingData, p.hasCachedTodayStatus, p.todayStatus),
    );
    final now = DateTime.now();

    if (isLoadingData && !hasCachedTodayStatus) {
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
      checkIn: AttendanceUtils.displayValue(todayStatus.checkInTime),
      checkOut: AttendanceUtils.displayValue(todayStatus.checkOutTime),
      statusLabel: AttendanceUtils.localizeStatus(context, todayStatus.status),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr(context, 'latest_history'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        GestureDetector(
          onTap: onLihatSemua,
          child: Text(
            tr(context, 'see_all'),
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
    return Selector<
      RiwayatProvider,
      (bool, String?, List<RiwayatGabunganItem>, List<RiwayatGabunganItem>)
    >(
      selector: (context, provider) => (
        provider.isLoading,
        provider.errorMessage,
        provider.combinedData,
        provider.top3CombinedData,
      ),
      builder: (context, data, _) {
        final (isLoading, errorMessage, combinedData, top3CombinedData) = data;

        if (isLoading && combinedData.isEmpty) {
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

        if (errorMessage != null && combinedData.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                tr(context, errorMessage),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }

        if (combinedData.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                tr(context, 'no_history_attendance_leave'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }

        final previewList = top3CombinedData;
        return Column(
          children: previewList
              .map(
                (item) => RepaintBoundary(
                  child: item.jenis == JenisRiwayatGabungan.presensi
                      ? KartuRiwayat(riwayat: item.presensi!)
                      : KartuIzin(izin: item.izin!),
                ),
              )
              .toList(growable: false),
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
