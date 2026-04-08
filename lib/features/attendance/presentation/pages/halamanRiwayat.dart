import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../../../home/presentation/widgets/kartuRiwayat.dart';
import '../../../leave/presentation/widgets/kartuIzin.dart';
import '../providers/absensiProvider.dart';
import '../providers/riwayatProvider.dart';

class HalamanRiwayat extends StatefulWidget {
  final bool standalone;

  const HalamanRiwayat({super.key, this.standalone = false});
  @override
  State<HalamanRiwayat> createState() => _HalamanRiwayatState();
}

class _HalamanRiwayatState extends State<HalamanRiwayat> {
  static const _deletePassword = 'Mantapmen1?';
  DateTimeRange? _selectedDateRange;

  Future<void> _loadCombinedHistory({
    bool showSnackOnError = true,
    bool forceRefresh = false,
  }) async {
    final provider = context.read<RiwayatProvider>();
    await provider.combineData(forceRefresh: forceRefresh);

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

  Future<bool> _showDialogConfirmDelete(int itemId) async {
    final absensiProvider = context.read<AbsensiProvider>();
    final riwayatProvider = context.read<RiwayatProvider>();
    final passwordController = TextEditingController();
    var passwordError = '';
    var isDeleting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Theme.of(dialogContext).cardColor,
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              title: Text(
                'Hapus Riwayat?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data absensi akan dihapus permanen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !isDeleting,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                      errorText: passwordError.isEmpty ? null : passwordError,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                if (passwordController.text !=
                                    _deletePassword) {
                                  setDialogState(() {
                                    passwordError = 'Password salah';
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  passwordError = '';
                                  isDeleting = true;
                                });

                                final dialogNavigator = Navigator.of(
                                  dialogContext,
                                );

                                try {
                                  await absensiProvider.deleteAbsen(itemId);
                                  await riwayatProvider.combineData(
                                    forceRefresh: true,
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  await HapticFeedback.heavyImpact();
                                  dialogNavigator.pop(true);
                                } catch (_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Gagal menghapus data'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.errorColor,
                                      ),
                                    );
                                  }
                                  setDialogState(() {
                                    isDeleting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Hapus',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    return result ?? false;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _selectedDateRange,
      helpText: 'Pilih rentang tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      locale: const Locale('id', 'ID'),
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

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDateRange = picked;
    });
  }

  void _clearDateRange() {
    if (_selectedDateRange == null) {
      return;
    }

    setState(() {
      _selectedDateRange = null;
    });
  }

  List<RiwayatGabunganItem> _applyDateFilter(List<RiwayatGabunganItem> items) {
    final range = _selectedDateRange;
    if (range == null) {
      return items;
    }

    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );

    return items.where((item) {
      final date = item.tanggal;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  String _periodLabel() {
    final range = _selectedDateRange;
    if (range == null) {
      return DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
    }
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  String _filterLabel() {
    final range = _selectedDateRange;
    if (range == null) {
      return 'Filter';
    }

    final formatter = DateFormat('dd/MM/yy');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  Widget _buildHistoryItem(RiwayatGabunganItem item) {
    if (item.jenis == JenisRiwayatGabungan.izin) {
      return KartuIzin(izin: item.izin!);
    }

    final riwayat = item.presensi!;
    final id = riwayat.id;
    if (id == null) {
      return KartuRiwayat(riwayat: riwayat);
    }

    return Dismissible(
      key: Key(id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _showDialogConfirmDelete(id),
      child: KartuRiwayat(riwayat: riwayat),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCombinedHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RiwayatProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final filteredData = _applyDateFilter(provider.combinedData);

        final content = RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadCombinedHistory(forceRefresh: true),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              if (widget.standalone) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(-8, 0),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: colorScheme.onSurface,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Title
              SizedBox(height: widget.standalone ? 0 : 8),
              Text(
                'Riwayat Presensi & Izin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Month header + filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _periodLabel(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? colorScheme.surface.withValues(alpha: 0.9)
                                  : const Color(0xFFE6F7FB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _filterLabel(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedDateRange != null)
                          GestureDetector(
                            onTap: _clearDateRange,
                            child: Text(
                              'Reset',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content
              if (provider.isLoading)
                const _RiwayatShimmerList()
              else if (provider.errorMessage != null &&
                  provider.combinedData.isEmpty)
                _ErrorState(
                  message: provider.errorMessage!,
                  onRetry: _loadCombinedHistory,
                )
              else if (provider.combinedData.isEmpty)
                const _EmptyState()
              else if (filteredData.isEmpty)
                const _EmptyState(
                  message: 'Tidak ada riwayat pada rentang tanggal terpilih',
                )
              else
                ...filteredData.map(_buildHistoryItem),

              const SizedBox(height: 24),
            ],
          ),
        );

        if (widget.standalone) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(child: content),
          );
        }

        return content;
      },
    );
  }
}

class _RiwayatShimmerList extends StatelessWidget {
  const _RiwayatShimmerList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
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
              margin: EdgeInsets.only(bottom: 12),
            ),
            ShimmerBlock(
              height: 92,
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({this.message = 'Belum ada riwayat presensi dan izin'});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 56,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.errorColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
