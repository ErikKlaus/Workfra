import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/widgets/languageDropdown.dart';
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

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;
    if (initialData != null) {
      _nameController.text = initialData.name;
      _emailController.text = initialData.email;
      _selectedTrainingId = initialData.trainingId;
      _selectedBatchId = initialData.batchId;
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

  List<String> _stepLabels() {
    return [
      tr(context, 'step_create_account'),
      tr(context, 'step_password'),
      tr(context, 'step_profile_photo'),
      tr(context, 'step_success'),
    ];
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr(context, 'validation_name_required');
    }

    if (value.trim().length < 2) {
      return tr(context, 'validation_name_min');
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr(context, 'validation_email_required');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return tr(context, 'validation_email_invalid');
    }

    return null;
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

  String _normalizeDropdownLabel(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // Validasi jenis kelamin
    if (authProvider.selectedGenderId == null ||
        authProvider.selectedGenderId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'gender_required')),
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
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(AppRadius.textField),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              tr(context, 'loading_data'),
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
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
            Expanded(
              child: Text(
                tr(context, 'load_data_failed_retry'),
                style: const TextStyle(
                  color: AppColors.errorColor,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(tr(context, 'reload'))),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      selectedItemBuilder: (context) {
        return items
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _normalizeDropdownLabel(item.nama),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false);
      },
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: item.id,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _normalizeDropdownLabel(item.nama),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: items.isEmpty ? null : onChanged,
      validator: (selected) {
        if (items.isEmpty) return emptyMessage;
        if (selected == null) {
          return tr(
            context,
            'required_select_template',
            params: {'field': label},
          );
        }
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'gender'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
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
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  tr(context, 'loading_data'),
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
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
                Expanded(
                  child: Text(
                    tr(context, 'gender_load_failed'),
                    style: const TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text(tr(context, 'reload')),
                ),
              ],
            ),
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.textField),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Text(
              tr(context, 'gender_unavailable'),
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
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
                      child: InkWell(
                        onTap: () => onChanged(item.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.nama,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.72,
                                          ),
                                  ),
                                ),
                              ),
                            ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const Spacer(),
                      const LanguageDropdown(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context, 'register_title'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  StepIndicator(currentStep: 0, labels: _stepLabels()),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _nameController,
                    label: tr(context, 'name'),
                    prefixIcon: Icons.person_outline,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: tr(context, 'email'),
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
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
                      label: tr(context, 'training_program'),
                      value: _selectedTrainingId,
                      items: state.items,
                      isLoading: state.isLoading,
                      errorMessage: state.error,
                      onChanged: _onSelectTraining,
                      onRetry: () =>
                          context.read<AuthProvider>().loadTrainings(),
                      emptyMessage: tr(context, 'training_unavailable'),
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
                      label: tr(context, 'batch'),
                      value: _selectedBatchId,
                      items: state.items,
                      isLoading: state.isLoading,
                      errorMessage: state.error,
                      onChanged: _onSelectBatch,
                      onRetry: () => context.read<AuthProvider>().loadBatches(),
                      emptyMessage: tr(context, 'batch_unavailable'),
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
                            tr(context, errorMessage),
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
                      text: tr(context, 'continue'),
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
