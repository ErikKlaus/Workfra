import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../models/dataRegistrasi.dart';
import 'halamanKataSandiDaftar.dart';
import 'halamanSukses.dart';
import '../providers/authProvider.dart';
import '../widgets/tombolUtama.dart';
import '../widgets/indikatorLangkah.dart';

class UploadPhotoPage extends StatefulWidget {
  final PendingRegistrationData? registrationData;

  const UploadPhotoPage({super.key, this.registrationData});

  @override
  State<UploadPhotoPage> createState() => _UploadPhotoPageState();
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _handleBack() async {
    if (!mounted) return;

    // During registration flow, back from step 3 should return to step 2.
    if (widget.registrationData != null) {
      final data = widget.registrationData!;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) =>
              HalamanKataSandiDaftar(
                registrationData: data.identity,
                initialPassword: data.password,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation =
                Tween<Offset>(
                  begin: const Offset(-0.06, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                );

            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
        ),
      );
      return;
    }

    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Pilih Sumber Foto',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _pickImageFromSource(source);
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
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
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SuccessPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final offsetAnimation =
                      Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      );

                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
          ),
        );
      }
      return;
    }

    if (_selectedImage != null) {
      final success = await authProvider.uploadPhoto(_selectedImage!.path);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SuccessPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final offsetAnimation =
                      Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      );

                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
          ),
        );
      }
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SuccessPage(),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Atur Foto Profil',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                const StepIndicator(currentStep: 2),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Center(
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
                            onTap: _showImageSourcePicker,
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
      ),
    );
  }
}
