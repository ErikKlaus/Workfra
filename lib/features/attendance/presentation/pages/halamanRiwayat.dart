import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
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
  static const _deletePassword = 'workfrakeren44';
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
          content: Text(tr(context, error)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<bool> _showDialogConfirmDelete(int itemId) async {
    final absensiProvider = context.read<AbsensiProvider>();
    final riwayatProvider = context.read<RiwayatProvider>();
    var password = '';
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
                tr(context, 'delete_history_title'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'delete_history_message'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        obscureText: true,
                        enabled: !isDeleting,
                        onChanged: (value) => password = value,
                        decoration: InputDecoration(
                          hintText: tr(context, 'enter_password'),
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          errorText: passwordError.isEmpty
                              ? null
                              : passwordError,
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
                ),
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
                          tr(context, 'cancel'),
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
                                final inputPassword = password.trim();
                                if (inputPassword != _deletePassword) {
                                  setDialogState(() {
                                    passwordError = tr(
                                      context,
                                      'password_wrong',
                                    );
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
                                  if (dialogNavigator.mounted) {
                                    dialogNavigator.pop(true);
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr(context, 'delete_failed'),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.errorColor,
                                      ),
                                    );
                                  }
                                  if (dialogNavigator.mounted) {
                                    setDialogState(() {
                                      isDeleting = false;
                                    });
                                  }
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
                                tr(context, 'delete'),
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

    return result ?? false;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _selectedDateRange,
      helpText: tr(context, 'date_range_help'),
      cancelText: tr(context, 'cancel'),
      confirmText: tr(context, 'apply'),
      locale: Locale(AppLocalizations.intlLocaleFromCode(
        Localizations.localeOf(context).languageCode,
      ).split('_').first),
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

  String _periodLabel(BuildContext context) {
    final range = _selectedDateRange;
    if (range == null) {
      return DateFormat('MMMM yyyy', context.intlLocale).format(DateTime.now());
    }
    final formatter = DateFormat('dd MMM yyyy', context.intlLocale);
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  String _filterLabel(BuildContext context) {
    final range = _selectedDateRange;
    if (range == null) {
      return tr(context, 'filter');
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
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.select<RiwayatProvider, bool>((p) => p.isLoading);
    final errorMessage = context.select<RiwayatProvider, String?>((p) => p.errorMessage);
    final combinedData = context.select<RiwayatProvider, List<RiwayatGabunganItem>>((p) => p.combinedData);
    final filteredData = _applyDateFilter(combinedData);

    final content = RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadCombinedHistory(forceRefresh: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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

              SizedBox(height: widget.standalone ? 0 : 8),
              Text(
                tr(context, 'history_screen_title'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _periodLabel(context),
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
                                  _filterLabel(context),
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
                              tr(context, 'reset'),
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
              ]),
            ),
          ),
          if (isLoading)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _RiwayatShimmerList()),
            )
          else if (errorMessage != null && combinedData.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _ErrorState(
                  message: tr(context, errorMessage),
                  onRetry: _loadCombinedHistory,
                ),
              ),
            )
          else if (combinedData.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _EmptyState(message: tr(context, 'no_history_attendance_leave')),
              ),
            )
          else if (filteredData.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _EmptyState(message: tr(context, 'no_history_selected_range')),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) => _buildHistoryItem(filteredData[index]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
  const _EmptyState({required this.message});

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
                tr(context, 'retry'),
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
