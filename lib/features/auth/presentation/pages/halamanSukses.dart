import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../widgets/tombolUtama.dart';
import '../widgets/indikatorLangkah.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Selamat datang di\n',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    TextSpan(
                      text: 'Workfra',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const StepIndicator(currentStep: 3),
              const Spacer(),
              Center(
                child: Lottie.asset(
                  'assets/animations/Smiling Owl.json',
                  width: 250,
                  height: 250,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Akun anda berhasil dibuat.\nSekarang presensi anda lebih mudah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.6,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Lanjut',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
