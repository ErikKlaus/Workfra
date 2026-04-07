import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../auth/presentation/providers/authProvider.dart';
import '../../../auth/presentation/pages/halamanOTP.dart';
import 'halamanPasswordBaru.dart';

class HalamanUbahPassword extends StatefulWidget {
  const HalamanUbahPassword({super.key});
  @override
  State<HalamanUbahPassword> createState() => _HalamanUbahPasswordState();
}

class _HalamanUbahPasswordState extends State<HalamanUbahPassword> {
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  Future<void> _sendOtp() async {
    final authProvider = context.read<AuthProvider>();
    final email = authProvider.user?.email;
    if (email == null || email.isEmpty) {
      setState(() {
        _errorMessage = 'Email user tidak tersedia. Silakan login ulang.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    authProvider.clearError();
    final success = await authProvider.forgotPassword(email: email);
    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (success) {
      // Navigasi ke OTP page dengan callback khusus (ke password baru, bukan reset-password)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HalamanOTP(
            onSuccess: () {
              // Setelah OTP berhasil diverifikasi, navigasi ke halaman password baru dari profil
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HalamanPasswordBaru(),
                ),
              );
            },
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage ?? 'Gagal mengirim OTP';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 24),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah Kata Sandi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mengirim kode verifikasi ke email anda...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 48),
              if (_isSending)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Mengirim kode OTP...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _sendOtp,
                    child: Text(
                      'Coba Lagi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
