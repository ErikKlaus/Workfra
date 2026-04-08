import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../localization/app_localizations.dart';
import '../services/networkService.dart';
import '../utils/navigatorKey.dart';
import 'requirementDialog.dart';

class GlobalRequirementObserver extends StatefulWidget {
  final Widget child;
  const GlobalRequirementObserver({super.key, required this.child});

  @override
  State<GlobalRequirementObserver> createState() =>
      _GlobalRequirementObserverState();
}

class _GlobalRequirementObserverState extends State<GlobalRequirementObserver>
    with WidgetsBindingObserver {
  final NetworkService _networkService = NetworkService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<ServiceStatus>? _locationServiceSubscription;

  bool _isRequirementDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRequirementWatchers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppRequirements();
    });
  }

  void _startRequirementWatchers() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      _,
    ) {
      _checkAppRequirements();
    });

    _locationServiceSubscription = Geolocator.getServiceStatusStream().listen((
      _,
    ) {
      _checkAppRequirements();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppRequirements();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _locationServiceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAppRequirements() async {
    if (!mounted || _isRequirementDialogVisible) return;

    final hasInternet = await _networkService.hasInternetConnection();
    final isGpsEnabled = await Geolocator.isLocationServiceEnabled();

    if (!mounted || (hasInternet && isGpsEnabled)) return;

    await _showGlobalRequirementDialog(
      hasInternet: hasInternet,
      isGpsEnabled: isGpsEnabled,
    );
  }

  Future<void> _showGlobalRequirementDialog({
    required bool hasInternet,
    required bool isGpsEnabled,
  }) async {
    if (!mounted || _isRequirementDialogVisible) return;

    final navigator = globalNavigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    final navContext = navigator.context;

    _isRequirementDialogVisible = true;
    await showRequirementDialog(
      navContext,
      title: tr(navContext, 'requirement_title'),
      message: _buildRequirementMessage(
        context: navContext,
        hasInternet: hasInternet,
        isGpsEnabled: isGpsEnabled,
      ),
      onReload: () async {
        final nextHasInternet = await _networkService.hasInternetConnection();
        final nextIsGpsEnabled = await Geolocator.isLocationServiceEnabled();
        return nextHasInternet && nextIsGpsEnabled;
      },
    );
    _isRequirementDialogVisible = false;
  }

  String _buildRequirementMessage({
    required BuildContext context,
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
