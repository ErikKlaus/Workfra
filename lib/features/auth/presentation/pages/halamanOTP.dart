import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../providers/authProvider.dart';
import '../widgets/tombolUtama.dart';

class HalamanOTP extends StatefulWidget {
  final VoidCallback? onSuccess;
  const HalamanOTP({super.key, this.onSuccess});
  @override
  State<HalamanOTP> createState() => _HalamanOTPState();
}

class _HalamanOTPState extends State<HalamanOTP> {
  final _pinController = PinInputController();
  String _otpValue = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifikasi() async {
    if (_otpValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan 6 digit kode OTP'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    final success = await authProvider.verifyOtp(otp: _otpValue);
    if (!mounted) return;
    if (success) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pushReplacementNamed('/reset-password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthProvider, String>((p) => p.resetEmail);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
                'Verifikasi OTP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Masukkan 6 digit kode yang telah kami kirimkan ke email anda: ',
                    ),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              MaterialPinField(
                length: 6,
                pinController: _pinController,
                onChanged: (value) {
                  setState(() {
                    _otpValue = value;
                  });
                },
                onCompleted: (_) => _handleVerifikasi(),
                keyboardType: TextInputType.number,
                theme: MaterialPinTheme(
                  shape: MaterialPinShape.outlined,
                  cellSize: const Size(48, 56),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  borderWidth: 1.5,
                  borderColor: AppColors.borderColor,
                  focusedBorderColor: AppColors.primary,
                  filledBorderColor: AppColors.primary,
                  fillColor: AppColors.surfaceColor,
                  focusedFillColor: AppColors.background,
                  cursorColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      const Text(
                        'Belum menerima kode?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: provider.canResendOtp
                                ? () => provider.resendOtp()
                                : null,
                            child: Text(
                              'Kirim Ulang Kode',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: provider.canResendOtp
                                    ? AppColors.primaryText
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ),
                          if (!provider.canResendOtp) ...[
                            const SizedBox(width: 8),
                            Text(
                              provider.timerText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Selector<AuthProvider, String?>(
                selector: (_, p) => p.errorMessage,
                builder: (context, errorMessage, _) {
                  if (errorMessage == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: AppColors.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Selector<AuthProvider, bool>(
                selector: (_, p) => p.isLoading,
                builder: (context, isLoading, _) => PrimaryButton(
                  text: 'Verifikasi',
                  isLoading: isLoading,
                  onPressed: _handleVerifikasi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
