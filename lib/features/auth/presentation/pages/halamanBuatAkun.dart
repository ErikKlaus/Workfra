import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/validasi.dart';
import '../../domain/entities/jenisKelamin.dart';
import '../../domain/entities/opsiDropdown.dart';
import '../models/dataRegistrasi.dart';
import 'halamanKataSandiDaftar.dart';
import '../providers/authProvider.dart';
import '../widgets/fieldTeks.dart';
import '../widgets/tombolUtama.dart';
import '../widgets/indikatorLangkah.dart';

class RegisterPage extends StatefulWidget {
  final RegisterIdentityData? initialData;

  const RegisterPage({super.key, this.initialData});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  int? _selectedTrainingId;
  int? _selectedBatchId;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;
    if (initialData != null) {
      _nameController.text = initialData.name;
      _emailController.text = initialData.email;
      _selectedTrainingId = initialData.trainingId;
      _selectedBatchId = initialData.batchId;
      _agreedToTerms = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      authProvider.resetRegisterState();
      authProvider.loadRegisterReferenceData(forceRefresh: true);
      if (widget.initialData != null) {
        authProvider.selectGender(widget.initialData!.genderId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggleTerms(bool? value) {
    setState(() {
      _agreedToTerms = value ?? false;
    });
  }

  void _onSelectTraining(int? value) {
    setState(() {
      _selectedTrainingId = value;
    });
  }

  void _onSelectBatch(int? value) {
    setState(() {
      _selectedBatchId = value;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // Validasi jenis kelamin
    if (authProvider.selectedGenderId == null ||
        authProvider.selectedGenderId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis kelamin wajib dipilih'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui syarat dan kebijakan privasi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    authProvider.clearError();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            HalamanKataSandiDaftar(
              registrationData: RegisterIdentityData(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                trainingId: _selectedTrainingId!,
                batchId: _selectedBatchId!,
                genderId: authProvider.selectedGenderId!,
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

  Widget _buildDropdownField({
    required String label,
    required int? value,
    required List<OpsiDropdown> items,
    required bool isLoading,
    required String? errorMessage,
    required ValueChanged<int?> onChanged,
    required VoidCallback onRetry,
    required String emptyMessage,
  }) {
    if (isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(AppRadius.textField),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Memuat data...',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.textField),
          border: Border.all(
            color: AppColors.errorColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Gagal memuat data. Coba lagi.',
                style: TextStyle(color: AppColors.errorColor, fontSize: 13),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Muat Ulang')),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<int>(value: item.id, child: Text(item.nama)),
          )
          .toList(growable: false),
      onChanged: items.isEmpty ? null : onChanged,
      validator: (selected) {
        if (items.isEmpty) return emptyMessage;
        if (selected == null) return '$label wajib dipilih';
        return null;
      },
      isExpanded: true,
      borderRadius: BorderRadius.circular(AppRadius.textField),
    );
  }

  /// Builds the gender radio button group with loading, error, and empty states.
  Widget _buildGenderRadioGroup({
    required List<JenisKelamin> items,
    required int? selectedId,
    required bool isLoading,
    required String? errorMessage,
    required ValueChanged<int> onChanged,
    required VoidCallback onRetry,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(AppRadius.textField),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Memuat data...',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          )
        else if (errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.textField),
              border: Border.all(
                color: AppColors.errorColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Gagal memuat data jenis kelamin.',
                    style: TextStyle(color: AppColors.errorColor, fontSize: 13),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Muat Ulang')),
              ],
            ),
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.textField),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const Text(
              'Data jenis kelamin tidak tersedia',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(AppRadius.textField),
            ),
            child: Column(
              children: items
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = selectedId == item.id;
                    final isLast = index == items.length - 1;
                    return Container(
                      decoration: !isLast
                          ? BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.borderColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      child: RadioListTile<int>(
                        value: item.id,
                        groupValue: selectedId,
                        onChanged: (value) {
                          if (value == null) return;
                          onChanged(value);
                        },
                        activeColor: AppColors.primary,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        title: Text(
                          item.nama,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primaryText
                                : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
                    'Buat Akun',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const StepIndicator(currentStep: 0),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nama',
                    prefixIcon: Icons.person_outline,
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
                  const SizedBox(height: 16),
                  Selector<
                    AuthProvider,
                    ({List<OpsiDropdown> items, bool isLoading, String? error})
                  >(
                    selector: (_, p) => (
                      items: p.daftarTraining,
                      isLoading: p.isLoadingTraining,
                      error: p.trainingError,
                    ),
                    builder: (context, state, _) => _buildDropdownField(
                      label: 'Program Pelatihan',
                      value: _selectedTrainingId,
                      items: state.items,
                      isLoading: state.isLoading,
                      errorMessage: state.error,
                      onChanged: _onSelectTraining,
                      onRetry: () =>
                          context.read<AuthProvider>().loadTrainings(),
                      emptyMessage: 'Data pelatihan tidak tersedia',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Selector<
                    AuthProvider,
                    ({List<OpsiDropdown> items, bool isLoading, String? error})
                  >(
                    selector: (_, p) => (
                      items: p.daftarBatch,
                      isLoading: p.isLoadingBatch,
                      error: p.batchError,
                    ),
                    builder: (context, state, _) => _buildDropdownField(
                      label: 'Batch',
                      value: _selectedBatchId,
                      items: state.items,
                      isLoading: state.isLoading,
                      errorMessage: state.error,
                      onChanged: _onSelectBatch,
                      onRetry: () => context.read<AuthProvider>().loadBatches(),
                      emptyMessage: 'Data batch tidak tersedia',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGenderRadioGroup(
                    items: authProvider.daftarGender,
                    selectedId: authProvider.selectedGenderId,
                    isLoading: authProvider.isLoadingGender,
                    errorMessage: authProvider.genderError,
                    onChanged: (value) {
                      context.read<AuthProvider>().selectGender(value);
                    },
                    onRetry: () => context.read<AuthProvider>().loadGenders(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: _toggleTerms,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Dengan anda mendaftar anda menyetujui syarat dan kebijakan privasi',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  Selector<AuthProvider, bool>(
                    selector: (_, p) => p.isLoading,
                    builder: (context, isLoading, _) => PrimaryButton(
                      text: 'Lanjut',
                      isLoading: isLoading,
                      onPressed: _handleRegister,
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
