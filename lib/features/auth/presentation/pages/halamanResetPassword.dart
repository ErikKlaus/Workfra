import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/validasi.dart';
import '../providers/authProvider.dart';
import '../widgets/fieldTeks.dart';
import '../widgets/tombolUtama.dart';

class HalamanResetPassword extends StatefulWidget {
  const HalamanResetPassword({super.key});
  @override
  State<HalamanResetPassword> createState() => _HalamanResetPasswordState();
}

class _HalamanResetPasswordState extends State<HalamanResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi tidak cocok'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    final success = await authProvider.resetPassword(
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diubah. Silakan masuk kembali.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
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
                  'Buat Kata Sandi Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cari yang mudah diingat',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Kata Sandi',
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
                    onPressed: () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Kata Sandi',
                  obscureText: _obscureConfirm,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.secondaryText,
                      size: 22,
                    ),
                    onPressed: () => setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    }),
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
                    text: 'Masuk',
                    icon: Icons.login,
                    isLoading: isLoading,
                    onPressed: _handleReset,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
