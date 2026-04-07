import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/validasi.dart';
import '../models/dataRegistrasi.dart';
import '../providers/authProvider.dart';
import '../widgets/fieldTeks.dart';
import '../widgets/indikatorLangkah.dart';
import '../widgets/tombolUtama.dart';
import 'halamanBuatAkun.dart';
import 'halamanFotoProfil.dart';

class HalamanKataSandiDaftar extends StatefulWidget {
  final RegisterIdentityData registrationData;
  final String? initialPassword;

  const HalamanKataSandiDaftar({
    super.key,
    required this.registrationData,
    this.initialPassword,
  });

  @override
  State<HalamanKataSandiDaftar> createState() => _HalamanKataSandiDaftarState();
}

class _HalamanKataSandiDaftarState extends State<HalamanKataSandiDaftar> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(
      text: widget.initialPassword ?? '',
    );
    _confirmPasswordController = TextEditingController(
      text: widget.initialPassword ?? '',
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterPage(initialData: widget.registrationData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(-0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi tidak cocok'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AuthProvider>().clearError();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            UploadPhotoPage(
              registrationData: widget.registrationData.withPassword(
                _passwordController.text,
              ),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back, size: 24),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kata Sandi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buat kata sandi untuk akun Anda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const StepIndicator(currentStep: 1),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Buat Kata Sandi',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.secondaryText,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Konfirmasi Kata Sandi',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    validator: Validators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.secondaryText,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      text: 'Lanjut',
                      isLoading: isLoading,
                      onPressed: _handleContinue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
