import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/networkService.dart';
import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/attendance_utils.dart';
import '../../../../core/widgets/requirementDialog.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../../../auth/presentation/providers/authProvider.dart';
import '../../../notification/presentation/providers/notifikasiProvider.dart';
import '../../../profile/presentation/providers/profileProvider.dart';
import '../../../../core/widgets/marquee_widget.dart';
import '../providers/presensiProvider.dart';

class HalamanPresensi extends StatefulWidget {
  const HalamanPresensi({super.key});

  @override
  State<HalamanPresensi> createState() => _HalamanPresensiState();
}

class _HalamanPresensiState extends State<HalamanPresensi> {
  final Completer<GoogleMapController> _mapController = Completer();
  final NetworkService _networkService = NetworkService();
  late final ValueNotifier<DateTime> _clockNotifier;
  late final ValueNotifier<bool> _outOfAreaNotifier;
  Timer? _clockTimer;
  Timer? _boundsValidationTimer;

  static const LatLng _officeLatLng = LatLng(-6.2108889, 106.8129444);
  static const double _focusRadiusMeters = 500;
  static const double _focusBoundsDelta = 0.0045;
  static const double _focusZoom = 17;
  static const Duration _boundsValidationDelay = Duration(milliseconds: 180);

  final LatLng _currentLatLng = _officeLatLng;
  LatLng? _userLatLng;
  late LatLngBounds _focusBounds;
  bool _isSnappingToBounds = false;

  String _resolvedAddress = '';
  bool _hasResolvedLocation = false;
  bool _isActionInProgress = false;

  // Status helpers delegated to shared AttendanceUtils

  String _badgeText({
    required bool isComplete,
    required bool hasCheckedIn,
    required String rawStatus,
  }) {
    if (isComplete) {
      return tr(context, 'status_done').toUpperCase();
    }
    if (!hasCheckedIn) {
      return tr(context, 'status_not_checked_in').toUpperCase();
    }

    final statusLabel = AttendanceUtils.localizeStatus(context, rawStatus);
    if (statusLabel == tr(context, 'status_unknown')) {
      return tr(context, 'status_active').toUpperCase();
    }

    return statusLabel.toUpperCase();
  }

  String _getUserName() {
    final authUser = context.read<AuthProvider>().user;
    if (authUser != null && authUser.name.trim().isNotEmpty) {
      return authUser.name;
    }

    final profile = context.read<ProfileProvider>().profile;
    if (profile != null && profile.name.trim().isNotEmpty) {
      return profile.name;
    }

    return tr(context, 'user_default_name');
  }

  String _localizeAddressText(String rawAddress) {
    final key = rawAddress.trim();

    // Handle translation keys stored by provider
    const addressKeys = [
      'loading_location',
      'location_fetch_failed',
      'address_not_found',
      'address_fetch_failed',
    ];
    if (addressKeys.contains(key)) {
      return tr(context, key);
    }

    // Legacy: fallback for old hardcoded Indonesian strings
    final normalized = key.toLowerCase();
    if (normalized.contains('memuat lokasi')) {
      return tr(context, 'loading_location');
    }
    if (normalized.contains('gagal mendapatkan lokasi')) {
      return tr(context, 'location_fetch_failed');
    }
    if (normalized.contains('alamat tidak ditemukan')) {
      return tr(context, 'address_not_found');
    }
    if (normalized.contains('gagal mendapatkan alamat')) {
      return tr(context, 'address_fetch_failed');
    }

    return rawAddress;
  }

  String _buildRequirementMessage({
    required bool hasInternet,
    required bool isGpsEnabled,
  }) {
    if (!hasInternet && !isGpsEnabled) {
      return tr(context, 'requirement_both');
    }

    if (!hasInternet) {
      return tr(context, 'requirement_internet');
    }

    return tr(context, 'requirement_gps');
  }

  bool _isWithinAttendanceRadius() {
    final user = _userLatLng;
    if (user == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      _officeLatLng.latitude,
      _officeLatLng.longitude,
    );

    return distance <= _focusRadiusMeters;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasResolvedLocation && _resolvedAddress.isEmpty) {
      _resolvedAddress = tr(context, 'loading_location');
    }
  }

  @override
  void initState() {
    super.initState();
    _focusBounds = _buildFocusBounds(_officeLatLng);
    _clockNotifier = ValueNotifier<DateTime>(DateTime.now());
    _outOfAreaNotifier = ValueNotifier<bool>(false);
    _startClockTicker();
    Future.microtask(_primeInitialData);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _boundsValidationTimer?.cancel();
    _clockNotifier.dispose();
    _outOfAreaNotifier.dispose();
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
      final localizedAddress = _localizeAddressText(nextAddress);
      if (_resolvedAddress != localizedAddress) {
        setState(() {
          _resolvedAddress = localizedAddress;
        });
      }
      return;
    }

    final nextLatLng = LatLng(position.latitude, position.longitude);
    final hasChanged =
        !_hasResolvedLocation ||
        _userLatLng?.latitude != nextLatLng.latitude ||
        _userLatLng?.longitude != nextLatLng.longitude ||
        _resolvedAddress != _localizeAddressText(nextAddress);

    if (!hasChanged) return;

    setState(() {
      _userLatLng = nextLatLng;
      _resolvedAddress = _localizeAddressText(nextAddress);
      _hasResolvedLocation = true;
    });

    if (animateMap) {
      unawaited(_recenter(_officeLatLng));
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
    _boundsValidationTimer?.cancel();
    await _moveCameraTo(target);
    _outOfAreaNotifier.value = false;
  }

  LatLngBounds _buildFocusBounds(LatLng center) {
    final south = (center.latitude - _focusBoundsDelta).clamp(-90.0, 90.0);
    final west = (center.longitude - _focusBoundsDelta).clamp(-180.0, 180.0);
    final north = (center.latitude + _focusBoundsDelta).clamp(-90.0, 90.0);
    final east = (center.longitude + _focusBoundsDelta).clamp(-180.0, 180.0);

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  bool _isOutOfFocusArea(LatLng target) {
    final lat = _currentLatLng.latitude;
    final lng = _currentLatLng.longitude;

    return target.latitude < lat - _focusBoundsDelta ||
        target.latitude > lat + _focusBoundsDelta ||
        target.longitude < lng - _focusBoundsDelta ||
        target.longitude > lng + _focusBoundsDelta;
  }

  Future<void> _focusCameraToBounds({
    required LatLngBounds bounds,
    required LatLng center,
  }) async {
    if (!_mapController.isCompleted) return;

    final controller = await _mapController.future;
    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: _focusZoom),
        ),
      );
    }
  }

  Future<void> _moveCameraTo(LatLng target) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, _focusZoom),
    );
  }

  Future<void> _snapBackToCenterFromAnyDirection() async {
    try {
      _boundsValidationTimer?.cancel();
      await _moveCameraTo(_currentLatLng);
      _outOfAreaNotifier.value = false;
    } finally {
      _isSnappingToBounds = false;
    }
  }

  void _scheduleBoundsValidation(LatLng target) {
    _boundsValidationTimer?.cancel();
    _boundsValidationTimer = Timer(_boundsValidationDelay, () {
      if (!mounted || _isSnappingToBounds) {
        return;
      }

      final isOutside = _isOutOfFocusArea(target);
      if (_outOfAreaNotifier.value != isOutside) {
        _outOfAreaNotifier.value = isOutside;
      }

      if (isOutside) {
        _isSnappingToBounds = true;
        unawaited(_snapBackToCenterFromAnyDirection());
      }
    });
  }

  void _handleMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }

    unawaited(
      _focusCameraToBounds(bounds: _focusBounds, center: _currentLatLng),
    );
  }

  void _handleCameraMove(CameraPosition position) {
    if (_isSnappingToBounds) {
      return;
    }

    _scheduleBoundsValidation(position.target);
  }

  Future<void> _handleAction() async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;

    try {
      final provider = context.read<PresensiProvider>();
      final status = provider.todayStatus;
      final isCheckInAction = !status.hasCheckedIn;

      if (status.isComplete) return;

      if (_userLatLng == null) {
        final message = tr(context, 'error_location_not_ready');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      if (!_isWithinAttendanceRadius()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'attendance_outside_area')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      bool success;
      if (isCheckInAction) {
        success = await provider.doCheckIn();
      } else {
        success = await provider.doCheckOut();
      }

      if (!mounted) return;

      if (success) {
        // Capture provider refs before async gap to avoid use_build_context_synchronously
        final notifProvider = context.read<NotifikasiProvider>();
        final localeCode = Localizations.localeOf(context).languageCode;
        await HapticFeedback.mediumImpact();
        _clockNotifier.value = provider.serverNow;

        unawaited(
          notifProvider.addPresensiNotification(
            isCheckIn: isCheckInAction,
            timeLabel: isCheckInAction
                ? provider.todayStatus.checkInTime
                : provider.todayStatus.checkOutTime,
            localeCode: localeCode,
          ),
        );
        if (!mounted) return;

        if (isCheckInAction) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop(true);
          } else {
            navigator.pushNamedAndRemoveUntil('/home', (_) => false);
          }
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCheckInAction
                  ? tr(context, 'attendance_check_in_success')
                  : tr(context, 'attendance_check_out_success'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        if (provider.isOutsideRadius) {
          if (!mounted) return;
          await showRequirementDialog(
            context,
            title: tr(context, 'attendance_rejected_title'),
            message: tr(context, 'error_outside_radius'),
            actionLabel: tr(context, 'close'),
            onReload: () async {
              return true; // Selalu izinkan dialog ditutup
            },
          );

          // Setelah dialog ditutup, kembalikan user ke beranda (Home)
          if (!mounted) return;
          Navigator.of(context).pop();
          return;
        }

        if (provider.isRequirementFailure) {
          final hasInternet = await _networkService.hasInternetConnection();
          final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
          if (!mounted) return;

          await showRequirementDialog(
            context,
            title: tr(context, 'attendance_rejected_title'),
            message: _buildRequirementMessage(
              hasInternet: hasInternet,
              isGpsEnabled: isGpsEnabled,
            ),
            onReload: () async {
              final nextHasInternet = await _networkService
                  .hasInternetConnection();
              final nextIsGpsEnabled =
                  await Geolocator.isLocationServiceEnabled();
              return nextHasInternet && nextIsGpsEnabled;
            },
          );
          return;
        }

        final fallbackMessage = tr(context, 'attendance_action_failed');
        final message = provider.errorMessage?.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message == null || message.isEmpty ? fallbackMessage : message,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isActionInProgress = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: _MapBackground(
              officeLatLng: _currentLatLng,
              userLatLng: _userLatLng,
              focusBounds: _focusBounds,
              onMapCreated: _handleMapCreated,
              onCameraMove: _handleCameraMove,
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
          Positioned(
            top: 102,
            left: 16,
            right: 80,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surface.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: MarqueeWidget(
                  child: Text(
                    tr(context, 'attendance_radius_area_label'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0FA9C4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 138,
            left: 16,
            right: 16,
            child: ValueListenableBuilder<bool>(
              valueListenable: _outOfAreaNotifier,
              builder: (context, isOutside, _) {
                if (!isOutside) {
                  return const SizedBox.shrink();
                }

                return IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tr(context, 'attendance_outside_area'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 176,
            left: 16,
            right: 16,
            child: Selector<PresensiProvider, bool>(
              selector: (_, provider) =>
                  provider.isLoadingMap && !provider.hasCachedLocation,
              builder: (context, isLoadingMap, _) {
                if (!isLoadingMap) {
                  return const SizedBox.shrink();
                }

                return IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surface.withValues(alpha: 0.94)
                            : Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr(context, 'attendance_fetching_location'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.42,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              final sheetColor = Theme.of(context).cardColor;
              return Container(
                decoration: BoxDecoration(
                  color: sheetColor,
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
                        color: colorScheme.outline.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: _SheetContent(
                          userName: userName,
                          userLatitude: _userLatLng?.latitude,
                          userLongitude: _userLatLng?.longitude,
                          address: _resolvedAddress,
                          clockListenable: _clockNotifier,
                          onActionTap: _handleAction,
                          statusColorResolver: AttendanceUtils.statusColor,
                          badgeTextResolver: _badgeText,
                          displayTimeResolver: AttendanceUtils.displayValue,
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
  final LatLng officeLatLng;
  final LatLng? userLatLng;
  final LatLngBounds focusBounds;
  final void Function(GoogleMapController controller) onMapCreated;
  final void Function(CameraPosition position) onCameraMove;

  const _MapBackground({
    required this.officeLatLng,
    required this.userLatLng,
    required this.focusBounds,
    required this.onMapCreated,
    required this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: officeLatLng,
        zoom: _HalamanPresensiState._focusZoom,
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(15, 19),
      cameraTargetBounds: CameraTargetBounds(focusBounds),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onMapCreated: onMapCreated,
      onCameraMove: onCameraMove,
      markers: {
        if (userLatLng != null)
          Marker(markerId: const MarkerId('user'), position: userLatLng!),
      },
      circles: {
        Circle(
          circleId: const CircleId('radius'),
          center: officeLatLng,
          radius: _HalamanPresensiState._focusRadiusMeters,
          fillColor: const Color(0xFF0FA9C4).withValues(alpha: 0.1),
          strokeColor: const Color(0xFF0FA9C4),
          strokeWidth: 2,
        ),
      },
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 52,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surface.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapIconButton(icon: Icons.add, onTap: onZoomIn),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
              _MapIconButton(icon: Icons.remove, onTap: onZoomOut),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 46,
        child: Icon(icon, color: colorScheme.onSurface, size: 21),
      ),
    );
  }
}

class _BackFloatingButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackFloatingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? colorScheme.surface.withValues(alpha: 0.88)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 22),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  final String userName;
  final double? userLatitude;
  final double? userLongitude;
  final String address;
  final ValueNotifier<DateTime> clockListenable;
  final VoidCallback onActionTap;
  final Color Function(String rawStatus) statusColorResolver;
  final String Function({
    required bool isComplete,
    required bool hasCheckedIn,
    required String rawStatus,
  })
  badgeTextResolver;
  final String Function(String? value) displayTimeResolver;

  const _SheetContent({
    required this.userName,
    required this.userLatitude,
    required this.userLongitude,
    required this.address,
    required this.clockListenable,
    required this.onActionTap,
    required this.statusColorResolver,
    required this.badgeTextResolver,
    required this.displayTimeResolver,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'attendance_today_title', params: {'name': userName}),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
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

            final statusColor = statusColorResolver(model.rawStatus);
            final badgeText = badgeTextResolver(
              isComplete: model.isComplete,
              hasCheckedIn: model.hasCheckedIn,
              rawStatus: model.rawStatus,
            );

            return ValueListenableBuilder<DateTime>(
              valueListenable: clockListenable,
              builder: (context, now, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                        Text(
                          DateFormat(
                            'EEE, d MMM',
                            context.intlLocale,
                          ).format(now),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                          ),
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
                            color: colorScheme.onSurface,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            tr(context, 'timezone_wib'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tr(context, 'check_in')}: ${displayTimeResolver(model.checkInTime)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userLatitude == null || userLongitude == null
                          ? tr(context, 'attendance_coordinates_unavailable')
                          : tr(
                              context,
                              'attendance_coordinates',
                              params: {
                                'lat': userLatitude!.toStringAsFixed(5),
                                'lng': userLongitude!.toStringAsFixed(5),
                              },
                            ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
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
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.gps_fixed, size: 14, color: Color(0xFF0FA9C4)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tr(context, 'attendance_radius_hint'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ),
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
              buttonLabel = tr(context, 'status_done').toUpperCase();
              buttonColor = colorScheme.onSurface.withValues(alpha: 0.55);
              buttonIcon = Icons.check_circle_outline_rounded;
              enabled = false;
            } else if (model.hasCheckedIn) {
              buttonLabel = tr(context, 'check_out_upper');
              buttonColor = const Color(0xFFEF4444);
              buttonIcon = Icons.logout_rounded;
              enabled = true;
            } else {
              buttonLabel = tr(context, 'check_in_upper');
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: colorScheme.outline.withValues(alpha: 0.5))
            : null,
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
          color: colorScheme.onSurface.withValues(alpha: 0.72),
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
