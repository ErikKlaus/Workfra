import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/temaAplikasi.dart';
import '../providers/notifikasiProvider.dart';
import '../widgets/kartuNotifikasi.dart';

class HalamanNotifikasi extends StatefulWidget {
  const HalamanNotifikasi({super.key});
  @override
  State<HalamanNotifikasi> createState() => _HalamanNotifikasiState();
}

class _HalamanNotifikasiState extends State<HalamanNotifikasi> {
  bool _isMarkingRead = false;

  Future<void> _markAsRead() async {
    if (_isMarkingRead) return;

    final provider = context.read<NotifikasiProvider>();
    if (!provider.hasUnread) return;

    _isMarkingRead = true;
    try {
      await provider.markAllAsRead();
    } finally {
      _isMarkingRead = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotifikasiProvider>().loadNotifikasi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          return;
        }
        await _markAsRead();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              onPressed: () async {
                await _markAsRead();
                if (!context.mounted) return;
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.arrow_back, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          title: Text(
            'Notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: Consumer<NotifikasiProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (provider.notifikasi.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada notifikasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              );
            }

            final hariIni = provider.notifikasiHariIni;
            final mingguIni = provider.notifikasiMingguIni;

            return ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (hariIni.isNotEmpty) ...[
                  _SectionHeader(title: 'Hari Ini'),
                  const SizedBox(height: 12),
                  ...hariIni.map((n) => KartuNotifikasi(notifikasi: n)),
                  const SizedBox(height: 8),
                ],
                if (mingguIni.isNotEmpty) ...[
                  _SectionHeader(title: 'Minggu Ini'),
                  const SizedBox(height: 12),
                  ...mingguIni.map((n) => KartuNotifikasi(notifikasi: n)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.72),
      ),
    );
  }
}
