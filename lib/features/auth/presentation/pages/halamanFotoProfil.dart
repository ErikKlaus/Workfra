import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../providers/authProvider.dart';
import '../widgets/tombolUtama.dart';
import '../widgets/indikatorLangkah.dart';

class PendingRegistrationData {
  final String name;
  final String email;
  final String password;
  final int trainingId;
  final int batchId;
  final int genderId;

  const PendingRegistrationData({
    required this.name,
    required this.email,
    required this.password,
    required this.trainingId,
    required this.batchId,
    required this.genderId,
  });
}

class UploadPhotoPage extends StatefulWidget {
  final PendingRegistrationData? registrationData;

  const UploadPhotoPage({super.key, this.registrationData});

  @override
  State<UploadPhotoPage> createState() => _UploadPhotoPageState();
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memilih foto'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleContinue() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    if (widget.registrationData != null) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil wajib diunggah sebelum membuat akun'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final data = widget.registrationData!;
      final success = await authProvider.registerWithPhoto(
        name: data.name,
        email: data.email,
        password: data.password,
        trainingId: data.trainingId,
        batchId: data.batchId,
        genderId: data.genderId,
        photoPath: _selectedImage!.path,
      );
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushReplacementNamed('/success');
      }
      return;
    }

    if (_selectedImage != null) {
      final success = await authProvider.uploadPhoto(_selectedImage!.path);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushReplacementNamed('/success');
      }
      return;
    }

    Navigator.of(context).pushReplacementNamed('/success');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atur Foto Profil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const StepIndicator(currentStep: 1),
              const Spacer(),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.borderColor.withValues(alpha: 0.5),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 72,
                              color: AppColors.secondaryText,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x300FA9C4),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.textOnPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
                  text: widget.registrationData != null
                      ? 'Buat Akun'
                      : 'Lanjut',
                  isLoading: isLoading,
                  onPressed: _handleContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
