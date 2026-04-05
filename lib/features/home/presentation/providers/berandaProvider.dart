import 'package:flutter/material.dart';

import '../../domain/entities/riwayat.dart';
import '../../domain/usecases/getRiwayatUsecase.dart';

class HomeProvider extends ChangeNotifier {
  final GetRiwayatUseCase _getRiwayatUseCase;
  HomeProvider({required GetRiwayatUseCase getRiwayatUseCase}) : _getRiwayatUseCase = getRiwayatUseCase;

  bool _isLoading = false;
  List<Riwayat> _riwayatTerbaru = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Riwayat> get riwayatTerbaru => _riwayatTerbaru;
  String? get errorMessage => _errorMessage;

  Future<void> loadRiwayat() async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try { _riwayatTerbaru = await _getRiwayatUseCase(); _isLoading = false; notifyListeners();
    } catch (e) { _errorMessage = 'Gagal memuat riwayat'; _isLoading = false; notifyListeners(); }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}
