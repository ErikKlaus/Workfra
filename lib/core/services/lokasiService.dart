import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Wrapper service for GPS location and reverse geocoding.
class LokasiService {
  /// Check and request location permissions, then return current position.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LokasiException('GPS tidak aktif. Aktifkan GPS terlebih dahulu.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LokasiException('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LokasiException(
        'Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    if (isMockLocation(position)) {
      throw const LokasiException(
        'Mock GPS/Fake GPS terdeteksi. Nonaktifkan mock location untuk melanjutkan.',
      );
    }

    developer.log(
      'getCurrentPosition → lat: ${position.latitude}, lng: ${position.longitude}',
      name: 'LokasiService',
    );
    return position;
  }

  /// Convert latitude/longitude to human-readable address string.
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return 'Alamat tidak ditemukan';

      final p = placemarks.first;
      final parts = <String>[
        if (p.street != null && p.street!.isNotEmpty) p.street!,
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
      ];

      final address = parts.isNotEmpty
          ? parts.join(', ')
          : 'Alamat tidak ditemukan';
      developer.log(
        'getAddressFromCoordinates → $address',
        name: 'LokasiService',
      );
      return address;
    } catch (e) {
      developer.log(
        'getAddressFromCoordinates error: $e',
        name: 'LokasiService',
      );
      return 'Gagal mendapatkan alamat';
    }
  }

  /// Detect whether a position originates from mock location provider.
  bool isMockLocation(Position position) {
    return position.isMocked;
  }
}

class LokasiException implements Exception {
  final String message;
  const LokasiException(this.message);

  @override
  String toString() => message;
}
