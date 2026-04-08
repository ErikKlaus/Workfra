import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/validasi.dart';
import '../../../auth/presentation/providers/authProvider.dart';
import '../../../auth/presentation/widgets/fieldTeks.dart';
import '../../../auth/presentation/widgets/tombolUtama.dart';

class HalamanPasswordBaru extends StatefulWidget {
  const HalamanPasswordBaru({super.key});
  @override
  State<HalamanPasswordBaru> createState() => _HalamanPasswordBaruState();
}

class _HalamanPasswordBaruState extends State<HalamanPasswordBaru> {
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
          content: Text('Kata sandi berhasil diubah'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Kembali ke halaman profil (pop sampai profil)
      Navigator.of(
        context,
      ).popUntil((route) => route.isFirst || route.settings.name == '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cari yang mudah diingat',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Kata Sandi Baru',
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                    text: 'Ubah Kata Sandi',
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
