import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/utils/transisiHalaman.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../../../attendance/presentation/pages/halamanRiwayat.dart';
import '../../../attendance/presentation/providers/riwayatProvider.dart';
import '../../../home/presentation/widgets/kartuRiwayat.dart';
import '../providers/izinProvider.dart';
import '../widgets/kartuIzin.dart';

class HalamanIzin extends StatefulWidget {
  const HalamanIzin({super.key});
  @override
  State<HalamanIzin> createState() => _HalamanIzinState();
}

class _HalamanIzinState extends State<HalamanIzin> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedType;
  final _reasonController = TextEditingController();

  static const _jenisIzin = ['Sakit', 'Izin', 'Lainnya'];

  Future<void> _loadIzinHistory({bool showSnackOnError = true}) async {
    final provider = context.read<IzinProvider>();
    await provider.getIzinHistory();

    if (!mounted || !showSnackOnError) {
      return;
    }

    final error = provider.errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIzinHistory();
      context.read<RiwayatProvider>().combineData();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<IzinProvider>();
    final success = await provider.createIzin(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      type: _selectedType!.toLowerCase(),
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = null;
        _selectedType = null;
      });
      _reasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin berhasil diajukan'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } else if (provider.submitError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.submitError!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IzinProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadIzinHistory,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Title
              const SizedBox(height: 8),
              Text(
                'Pengajuan Izin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Form card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date picker
                      Text(
                        'Pilih tanggal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate != null
                                    ? DateFormat(
                                        'dd MMMM yyyy',
                                        'id_ID',
                                      ).format(_selectedDate!)
                                    : 'mm/dd/yyyy',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedDate != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.65,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Type dropdown
                      Text(
                        'Jenis Izin',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          hintText: 'Pilih kategori...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: _jenisIzin
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _selectedType = val),
                        validator: (val) =>
                            val == null ? 'Pilih jenis izin' : null,
                      ),
                      const SizedBox(height: 20),

                      // Reason
                      Text(
                        'Tulis alasan izin...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 68),
                            child: Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                          hintText: 'Jelaskan alasan izin Anda...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Alasan tidak boleh kosong'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: provider.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ajukan Izin',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.send_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Divider
              Divider(
                color: AppColors.borderColor.withValues(alpha: 0.6),
                thickness: 1,
              ),
              const SizedBox(height: 20),

              // Leave history section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Izin Anda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        buildFadeRoute(const HalamanRiwayat(standalone: true)),
                      );
                    },
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // History content - uses RiwayatProvider (same data as "Lihat Semua")
              Consumer<RiwayatProvider>(
                builder: (context, riwayatProvider, _) {
                  if (riwayatProvider.isLoading &&
                      riwayatProvider.combinedData.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: ShimmerSkeleton(
                        child: Column(
                          children: [
                            ShimmerBlock(
                              height: 92,
                              borderRadius: BorderRadius.all(
                                Radius.circular(32),
                              ),
                              margin: EdgeInsets.only(bottom: 12),
                            ),
                            ShimmerBlock(
                              height: 92,
                              borderRadius: BorderRadius.all(
                                Radius.circular(32),
                              ),
                              margin: EdgeInsets.only(bottom: 12),
                            ),
                            ShimmerBlock(
                              height: 92,
                              borderRadius: BorderRadius.all(
                                Radius.circular(32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (riwayatProvider.combinedData.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada riwayat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final previewList = riwayatProvider.combinedData
                      .take(3)
                      .toList();
                  return Column(
                    children: previewList
                        .map(
                          (item) => item.jenis == JenisRiwayatGabungan.presensi
                              ? KartuRiwayat(riwayat: item.presensi!)
                              : KartuIzin(izin: item.izin!),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
