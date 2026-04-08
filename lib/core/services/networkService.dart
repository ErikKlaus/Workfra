import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to validate active network transport used by attendance flow.
class NetworkService {
  final Connectivity _connectivity;

  NetworkService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Returns true when internet transport is available (Wi-Fi or mobile data).
  Future<bool> hasInternetConnection() async {
    final dynamic result = await _connectivity.checkConnectivity();

    if (result is ConnectivityResult) {
      return _isInternetTransport(result);
    }

    if (result is List<ConnectivityResult>) {
      return result.any(_isInternetTransport);
    }

    return false;
  }

  bool _isInternetTransport(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn;
  }
}
