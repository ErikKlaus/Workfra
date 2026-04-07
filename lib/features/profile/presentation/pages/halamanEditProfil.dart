import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/validasi.dart';
import '../../../auth/presentation/widgets/fieldTeks.dart';
import '../../../auth/presentation/widgets/tombolUtama.dart';
import '../providers/profileProvider.dart';

class HalamanEditProfil extends StatefulWidget {
  const HalamanEditProfil({super.key});

  @override
  State<HalamanEditProfil> createState() => _HalamanEditProfilState();
}

class _HalamanEditProfilState extends State<HalamanEditProfil> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final currentProfile = context.read<ProfileProvider>().profile;
    _nameController = TextEditingController(text: currentProfile?.name ?? '');
    _emailController = TextEditingController(text: currentProfile?.email ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.loadProfile();
      if (!mounted) return;
      final latestProfile = profileProvider.profile;
      if (latestProfile == null) return;

      _nameController.text = latestProfile.name;
      _emailController.text = latestProfile.email;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final profileProvider = context.read<ProfileProvider>();
    profileProvider.clearError();
    final success = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
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
                  'Edit Profil',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perbarui informasi pribadi anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 24),
                Selector<ProfileProvider, String?>(
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
                Selector<ProfileProvider, bool>(
                  selector: (_, p) => p.isLoading,
                  builder: (context, isLoading, _) => PrimaryButton(
                    text: 'Simpan Perubahan',
                    isLoading: isLoading,
                    onPressed: _handleSave,
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
