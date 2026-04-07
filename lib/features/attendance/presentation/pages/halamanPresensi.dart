import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../../../auth/presentation/providers/authProvider.dart';
import '../../../notification/presentation/providers/notifikasiProvider.dart';
import '../../../profile/presentation/providers/profileProvider.dart';
import '../providers/presensiProvider.dart';

class HalamanPresensi extends StatefulWidget {
  const HalamanPresensi({super.key});

  @override
  State<HalamanPresensi> createState() => _HalamanPresensiState();
}

class _HalamanPresensiState extends State<HalamanPresensi> {
  final Completer<GoogleMapController> _mapController = Completer();
  late final ValueNotifier<DateTime> _clockNotifier;
  Timer? _clockTimer;

  static const LatLng _fallbackLatLng = LatLng(-6.2088, 106.8456);

  LatLng _currentLatLng = _fallbackLatLng;
  String _resolvedAddress = 'Memuat lokasi...';
  bool _hasResolvedLocation = false;

  String _mapStatusLabel(String rawStatus) {
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

  Color _statusColor(String statusLabel) {
    if (statusLabel == 'Telat') {
      return const Color(0xFFF59E0B);
    }
    if (statusLabel == 'Absen') {
      return const Color(0xFFEF4444);
    }
    if (statusLabel == 'Hadir') {
      return const Color(0xFF22C55E);
    }
    return AppColors.secondaryText;
  }

  String _badgeText({
    required bool isComplete,
    required bool hasCheckedIn,
    required String statusLabel,
  }) {
    if (isComplete) {
      return 'SELESAI';
    }
    if (!hasCheckedIn) {
      return 'BELUM CHECK IN';
    }
    if (statusLabel == '-') {
      return 'STATUS AKTIF';
    }
    return statusLabel.toUpperCase();
  }

  String _displayTime(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '-';
    }
    return normalized;
  }

  String _getUserName() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null) return profile.name;
    return context.read<AuthProvider>().user?.name ?? 'User';
  }

  @override
  void initState() {
    super.initState();
    _clockNotifier = ValueNotifier<DateTime>(DateTime.now());
    _startClockTicker();
    Future.microtask(_primeInitialData);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _clockNotifier.dispose();
    super.dispose();
  }

  void _startClockTicker() {
    _clockNotifier.value = context.read<PresensiProvider>().serverNow;
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _clockNotifier.value = context.read<PresensiProvider>().serverNow;
    });
  }

  Future<void> _primeInitialData() async {
    if (!mounted) return;

    final provider = context.read<PresensiProvider>();
    await Future.wait([
      provider.getCurrentLocation(),
      provider.loadTodayStatus(),
    ]);

    if (!mounted) return;

    _clockNotifier.value = provider.serverNow;
    _captureLocationSnapshot(provider, animateMap: true);
  }

  void _captureLocationSnapshot(
    PresensiProvider provider, {
    bool animateMap = false,
  }) {
    final position = provider.currentPosition;
    final nextAddress = provider.currentAddress;

    if (position == null) {
      if (_resolvedAddress != nextAddress) {
        setState(() {
          _resolvedAddress = nextAddress;
        });
      }
      return;
    }

    final nextLatLng = LatLng(position.latitude, position.longitude);
    final hasChanged =
        !_hasResolvedLocation ||
        _currentLatLng.latitude != nextLatLng.latitude ||
        _currentLatLng.longitude != nextLatLng.longitude ||
        _resolvedAddress != nextAddress;

    if (!hasChanged) return;

    setState(() {
      _currentLatLng = nextLatLng;
      _resolvedAddress = nextAddress;
      _hasResolvedLocation = true;
    });

    if (animateMap) {
      unawaited(_recenter(nextLatLng));
    }
  }

  Future<void> _zoomIn() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _recenter(LatLng target) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newLatLng(target));
  }

  Future<void> _handleAction() async {
    final provider = context.read<PresensiProvider>();
    final status = provider.todayStatus;

    if (status.isComplete) return;

    bool success;
    if (!status.hasCheckedIn) {
      success = await provider.doCheckIn();
    } else {
      success = await provider.doCheckOut();
    }

    if (!mounted) return;

    if (success) {
      _clockNotifier.value = provider.serverNow;

      unawaited(
        context.read<NotifikasiProvider>().addPresensiNotification(
          isCheckIn: !status.hasCheckedIn,
          timeLabel: !status.hasCheckedIn
              ? provider.todayStatus.checkInTime
              : provider.todayStatus.checkOutTime,
        ),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !status.hasCheckedIn ? 'Check-in berhasil!' : 'Check-out berhasil!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: _MapBackground(
              currentLatLng: _currentLatLng,
              hasLocation: _hasResolvedLocation,
              mapController: _mapController,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66F9F9FC), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: _BackFloatingButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: _MapControlPanel(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onRecenter: () => _recenter(_currentLatLng),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.42,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 22,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E2E5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: _SheetContent(
                          userName: userName,
                          latitude: _currentLatLng.latitude,
                          longitude: _currentLatLng.longitude,
                          address: _resolvedAddress,
                          clockListenable: _clockNotifier,
                          onActionTap: _handleAction,
                          mapStatusLabel: _mapStatusLabel,
                          statusColorResolver: _statusColor,
                          badgeTextResolver: _badgeText,
                          displayTimeResolver: _displayTime,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  final LatLng currentLatLng;
  final bool hasLocation;
  final Completer<GoogleMapController> mapController;

  const _MapBackground({
    required this.currentLatLng,
    required this.hasLocation,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: currentLatLng, zoom: 16),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onMapCreated: (controller) {
        if (!mapController.isCompleted) {
          mapController.complete(controller);
        }

        if (hasLocation) {
          controller.animateCamera(CameraUpdate.newLatLng(currentLatLng));
        }
      },
      markers: hasLocation
          ? {
              Marker(
                markerId: const MarkerId('current_position'),
                position: currentLatLng,
              ),
            }
          : {},
    );
  }
}


class _MapControlPanel extends StatelessWidget {
  final Future<void> Function() onZoomIn;
  final Future<void> Function() onZoomOut;
  final Future<void> Function() onRecenter;

  const _MapControlPanel({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapIconButton(icon: Icons.add, onTap: onZoomIn),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE7E7EA)),
              _MapIconButton(icon: Icons.remove, onTap: onZoomOut),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE7E7EA)),
              _MapIconButton(icon: Icons.gps_fixed, onTap: onRecenter),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final Future<void> Function() onTap;

  const _MapIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 46,
        child: Icon(icon, color: const Color(0xFF111827), size: 21),
      ),
    );
  }
}

class _BackFloatingButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackFloatingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: Color(0xFF111827), size: 22),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  final String userName;
  final double latitude;
  final double longitude;
  final String address;
  final ValueNotifier<DateTime> clockListenable;
  final VoidCallback onActionTap;
  final String Function(String rawStatus) mapStatusLabel;
  final Color Function(String statusLabel) statusColorResolver;
  final String Function({
    required bool isComplete,
    required bool hasCheckedIn,
    required String statusLabel,
  })
  badgeTextResolver;
  final String Function(String? value) displayTimeResolver;

  const _SheetContent({
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.clockListenable,
    required this.onActionTap,
    required this.mapStatusLabel,
    required this.statusColorResolver,
    required this.badgeTextResolver,
    required this.displayTimeResolver,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presensi Hari Ini, $userName',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Selector<PresensiProvider, _StatusHeaderViewModel>(
          selector: (_, provider) => _StatusHeaderViewModel(
            showLoading:
                provider.isLoadingData && !provider.hasCachedTodayStatus,
            isComplete: provider.todayStatus.isComplete,
            hasCheckedIn: provider.todayStatus.hasCheckedIn,
            rawStatus: provider.todayStatus.status,
            checkInTime: provider.todayStatus.checkInTime,
            checkOutTime: provider.todayStatus.checkOutTime,
          ),
          builder: (context, model, _) {
            if (model.showLoading) {
              return const _StatusHeaderShimmer();
            }

            final statusLabel = mapStatusLabel(model.rawStatus);
            final statusColor = statusColorResolver(statusLabel);
            final badgeText = badgeTextResolver(
              isComplete: model.isComplete,
              hasCheckedIn: model.hasCheckedIn,
              statusLabel: statusLabel,
            );

            return ValueListenableBuilder<DateTime>(
              valueListenable: clockListenable,
              builder: (context, now, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              badgeText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('EEE, d MMM').format(now),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${DateFormat('HH:mm').format(now)} WIB',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(now),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            'WIB',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check-in: ${displayTimeResolver(model.checkInTime)}  •  Check-out: ${displayTimeResolver(model.checkOutTime)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Lat ${latitude.toStringAsFixed(5)}, Lng ${longitude.toStringAsFixed(5)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        _AddressCard(address: address),
        const SizedBox(height: 16),
        Selector<PresensiProvider, _ActionButtonViewModel>(
          selector: (_, provider) => _ActionButtonViewModel(
            isComplete: provider.todayStatus.isComplete,
            hasCheckedIn: provider.todayStatus.hasCheckedIn,
            isSubmitting: provider.isSubmitting,
          ),
          builder: (context, model, _) {
            String buttonLabel;
            Color buttonColor;
            IconData buttonIcon;
            bool enabled;

            if (model.isComplete) {
              buttonLabel = 'SELESAI';
              buttonColor = AppColors.secondaryText;
              buttonIcon = Icons.check_circle_outline_rounded;
              enabled = false;
            } else if (model.hasCheckedIn) {
              buttonLabel = 'CHECK OUT';
              buttonColor = const Color(0xFFEF4444);
              buttonIcon = Icons.logout_rounded;
              enabled = true;
            } else {
              buttonLabel = 'CHECK IN';
              buttonColor = const Color(0xFF00B415);
              buttonIcon = Icons.login_rounded;
              enabled = true;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: enabled && !model.isSubmitting
                      ? onActionTap
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: buttonColor.withValues(
                      alpha: 0.45,
                    ),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: model.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(buttonIcon, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              buttonLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatusHeaderViewModel {
  final bool showLoading;
  final bool isComplete;
  final bool hasCheckedIn;
  final String rawStatus;
  final String? checkInTime;
  final String? checkOutTime;

  const _StatusHeaderViewModel({
    required this.showLoading,
    required this.isComplete,
    required this.hasCheckedIn,
    required this.rawStatus,
    required this.checkInTime,
    required this.checkOutTime,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _StatusHeaderViewModel &&
        other.showLoading == showLoading &&
        other.isComplete == isComplete &&
        other.hasCheckedIn == hasCheckedIn &&
        other.rawStatus == rawStatus &&
        other.checkInTime == checkInTime &&
        other.checkOutTime == checkOutTime;
  }

  @override
  int get hashCode => Object.hash(
    showLoading,
    isComplete,
    hasCheckedIn,
    rawStatus,
    checkInTime,
    checkOutTime,
  );
}

class _ActionButtonViewModel {
  final bool isComplete;
  final bool hasCheckedIn;
  final bool isSubmitting;

  const _ActionButtonViewModel({
    required this.isComplete,
    required this.hasCheckedIn,
    required this.isSubmitting,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ActionButtonViewModel &&
        other.isComplete == isComplete &&
        other.hasCheckedIn == hasCheckedIn &&
        other.isSubmitting == isSubmitting;
  }

  @override
  int get hashCode => Object.hash(isComplete, hasCheckedIn, isSubmitting);
}

class _AddressCard extends StatelessWidget {
  final String address;

  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        address,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryText,
          height: 1.35,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusHeaderShimmer extends StatelessWidget {
  const _StatusHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return const ShimmerSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBlock(
                width: 114,
                height: 22,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              ShimmerBlock(
                width: 86,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
          SizedBox(height: 8),
          ShimmerBlock(
            width: 130,
            height: 30,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(height: 4),
          ShimmerBlock(
            height: 14,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(height: 3),
          ShimmerBlock(
            width: 180,
            height: 12,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ],
      ),
    );
  }
}
