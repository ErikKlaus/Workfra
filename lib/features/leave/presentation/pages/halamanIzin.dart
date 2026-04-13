import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/networkService.dart';
import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/widgets/requirementDialog.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../../../attendance/presentation/providers/riwayatProvider.dart';
import '../../domain/entities/izin.dart';
import 'halamanSemuaIzin.dart';
import '../providers/izinProvider.dart';
import '../widgets/kartuIzin.dart';

class HalamanIzin extends StatefulWidget {
  const HalamanIzin({super.key});
  @override
  State<HalamanIzin> createState() => _HalamanIzinState();
}

class _HalamanIzinState extends State<HalamanIzin> {
  final _formKey = GlobalKey<FormState>();
  final NetworkService _networkService = NetworkService();
  DateTime? _selectedDate;
  String? _selectedType;
  final _reasonController = TextEditingController();

  static const _jenisIzin = ['sakit', 'izin', 'lainnya'];

  bool _isExcludedType(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.contains('sakit') ||
        normalized.contains('lain') ||
        normalized.contains('other');
  }

  bool _looksLikePermission(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty || _isExcludedType(normalized)) {
      return false;
    }

    return normalized == 'izin' ||
        normalized == 'ijin' ||
        normalized == 'permission' ||
        normalized == 'leave' ||
        normalized.contains('izin') ||
        normalized.contains('ijin') ||
        normalized.contains('permission') ||
        normalized.contains('leave');
  }

  List<Izin> _permissionOnlyList(List<RiwayatGabunganItem> combined) {
    final fromIzin = combined
        .where((item) {
          if (item.jenis != JenisRiwayatGabungan.izin || item.izin == null) {
            return false;
          }
          final type = item.izin!.type;
          if (_isExcludedType(type)) {
            return false;
          }
          return _looksLikePermission(type) || type.trim().isEmpty;
        })
        .map((item) {
          final izin = item.izin!;
          return Izin(
            id: izin.id,
            type: 'izin',
            date: izin.date,
            reason: izin.reason.trim().isEmpty ? '-' : izin.reason,
            status: izin.status,
            processedAt: izin.processedAt,
            rejectionReason: izin.rejectionReason,
          );
        })
        .toList();

    if (fromIzin.isNotEmpty) {
      return fromIzin;
    }

    // Fallback: use attendance history with izin-like status when leave endpoint is empty.
    return combined
        .where((item) {
          if (item.jenis != JenisRiwayatGabungan.presensi ||
              item.presensi == null) {
            return false;
          }
          final status = item.presensi!.status;
          return _looksLikePermission(status) && !_isExcludedType(status);
        })
        .map((item) {
          final presensi = item.presensi!;
          return Izin(
            id: presensi.id,
            type: 'izin',
            date: presensi.tanggal,
            reason: '-',
            status: StatusIzin.approved,
          );
        })
        .toList();
  }

  String _leaveTypeLabel(String type) {
    switch (type) {
      case 'sakit':
        return tr(context, 'leave_type_sick');
      case 'izin':
        return tr(context, 'leave_type_permission');
      default:
        return tr(context, 'leave_type_other');
    }
  }

  String _normalizeDropdownLabel(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _loadIzinHistory({bool showSnackOnError = true}) async {
    final provider = context.read<RiwayatProvider>();
    await provider.combineData(forceRefresh: true);

    if (!mounted || !showSnackOnError) {
      return;
    }

    final error = provider.errorMessage;
    if (error != null && error.isNotEmpty) {
      final isRetryable = _isRetryableError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, error)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorColor,
          action: isRetryable
              ? SnackBarAction(
                  label: tr(context, 'retry'),
                  textColor: Colors.white,
                  onPressed: () {
                    _loadIzinHistory();
                  },
                )
              : null,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIzinHistory();
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
      confirmText: 'Oke',
      locale: Locale(
        AppLocalizations.intlLocaleFromCode(
          Localizations.localeOf(context).languageCode,
        ).split('_').first,
      ),
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
    final hasInternet = await _networkService.hasInternetConnection();
    final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;

    if (!hasInternet || !isGpsEnabled) {
      await showRequirementDialog(
        context,
        title: tr(context, 'requirement_title'),
        message: _buildRequirementMessage(
          hasInternet: hasInternet,
          isGpsEnabled: isGpsEnabled,
        ),
        onReload: () async {
          final nextHasInternet = await _networkService.hasInternetConnection();
          final nextIsGpsEnabled = await Geolocator.isLocationServiceEnabled();
          return nextHasInternet && nextIsGpsEnabled;
        },
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'select_date_first')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<IzinProvider>();
    final success = await provider.createIzin(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      type: _selectedType!,
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await context.read<RiwayatProvider>().combineData(forceRefresh: true);

      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = null;
        _selectedType = null;
      });
      _reasonController.clear();
      await HapticFeedback.mediumImpact();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              provider.lastSubmitQueued
                  ? 'leave_queued_offline'
                  : 'leave_submitted_success',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: provider.lastSubmitQueued
              ? const Color(0xFFF59E0B)
              : const Color(0xFF22C55E),
        ),
      );
    } else if (provider.submitError != null) {
      final submitError = provider.submitError!;
      final isRetryable = _isRetryableError(submitError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, submitError)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorColor,
          action: isRetryable
              ? SnackBarAction(
                  label: tr(context, 'retry'),
                  textColor: Colors.white,
                  onPressed: _submit,
                )
              : null,
        ),
      );
    }
  }

  bool _isRetryableError(String errorKey) {
    const retryableKeys = {
      'error_network_unreachable',
      'error_request_timeout',
      'error_connection_lost',
      'error_server_unavailable',
    };
    return retryableKeys.contains(errorKey);
  }

  String _buildRequirementMessage({
    required bool hasInternet,
    required bool isGpsEnabled,
  }) {
    if (!hasInternet && !isGpsEnabled) {
      return tr(context, 'requirement_both');
    }
    if (!hasInternet) {
      return tr(context, 'requirement_internet');
    }
    return tr(context, 'requirement_gps');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSubmitting = context.select<IzinProvider, bool>(
      (p) => p.isSubmitting,
    );
    final riwayatIsLoading = context.select<RiwayatProvider, bool>(
      (p) => p.isLoading,
    );
    final combinedData = context
        .select<RiwayatProvider, List<RiwayatGabunganItem>>(
          (p) => p.combinedData,
        );
    final izinOnly = _permissionOnlyList(combinedData);
    final previewList = izinOnly.take(3).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadIzinHistory,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'leave_title'),
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
                            tr(context, 'pick_date'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
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
                                border: Border.all(
                                  color: AppColors.borderColor,
                                ),
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
                                            context.intlLocale,
                                          ).format(_selectedDate!)
                                        : tr(context, 'date_placeholder'),
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
                            tr(context, 'leave_type'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.category_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                              hintText: tr(context, 'select_category'),
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
                                      _normalizeDropdownLabel(
                                        _leaveTypeLabel(e),
                                      ),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedType = val),
                            validator: (val) => val == null
                                ? tr(context, 'leave_type_required')
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Reason
                          Text(
                            tr(context, 'leave_reason_label'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
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
                              hintText: tr(context, 'leave_reason_hint'),
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
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? tr(context, 'leave_reason_required')
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
                      onPressed: isSubmitting ? null : _submit,
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
                      child: isSubmitting
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
                                  tr(context, 'submit_leave'),
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
                  const SizedBox(height: 20),

                  // Divider
                  Divider(
                    color: AppColors.borderColor.withValues(alpha: 0.6),
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),

                  // Leave history section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(context, 'your_leave_history'),
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
                            MaterialPageRoute(
                              builder: (_) => const HalamanSemuaIzin(),
                            ),
                          );
                        },
                        child: Text(
                          tr(context, 'see_all'),
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
                ],
              ),
            ),
          ),

          if (riwayatIsLoading && izinOnly.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              sliver: SliverToBoxAdapter(
                child: ShimmerSkeleton(
                  child: Column(
                    children: [
                      ShimmerBlock(
                        height: 92,
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                        margin: EdgeInsets.only(bottom: 12),
                      ),
                      ShimmerBlock(
                        height: 92,
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                        margin: EdgeInsets.only(bottom: 12),
                      ),
                      ShimmerBlock(
                        height: 92,
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (izinOnly.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(context, 'no_history_yet'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: previewList.length,
                itemBuilder: (context, index) =>
                    KartuIzin(izin: previewList[index]),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
