import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to validate active network transport used by attendance flow.
class NetworkService {
  final Connectivity _connectivity;
  DateTime? _lastCheckAt;
  bool _lastConnectivityResult = false;

  static const Duration _connectivityCacheTTL = Duration(seconds: 3);

  NetworkService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Returns true when internet transport is available (Wi-Fi or mobile data).
  Future<bool> hasInternetConnection({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastCheckAt != null &&
        now.difference(_lastCheckAt!) < _connectivityCacheTTL) {
      return _lastConnectivityResult;
    }

    final dynamic result = await _connectivity.checkConnectivity();

    _lastCheckAt = DateTime.now();

    if (result is ConnectivityResult) {
      _lastConnectivityResult = _isInternetTransport(result);
      return _lastConnectivityResult;
    }

    if (result is List<ConnectivityResult>) {
      _lastConnectivityResult = result.any(_isInternetTransport);
      return _lastConnectivityResult;
    }

    _lastConnectivityResult = false;
    return false;
  }

  bool _isInternetTransport(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn;
  }
}
