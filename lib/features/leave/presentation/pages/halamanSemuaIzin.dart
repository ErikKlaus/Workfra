import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/shimmerSkeleton.dart';
import '../../../attendance/presentation/providers/riwayatProvider.dart';
import '../widgets/kartuIzin.dart';

class HalamanSemuaIzin extends StatefulWidget {
  const HalamanSemuaIzin({super.key});

  @override
  State<HalamanSemuaIzin> createState() => _HalamanSemuaIzinState();
}

class _HalamanSemuaIzinState extends State<HalamanSemuaIzin> {
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiwayatProvider>().combineData(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final provider = context.read<RiwayatProvider>();
    final izinOnly = provider.combinedData
        .where(
          (item) =>
              item.jenis == JenisRiwayatGabungan.izin && item.izin != null,
        )
        .map((item) => item.izin!)
        .toList();

    if (_visibleCount < izinOnly.length) {
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, izinOnly.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<RiwayatProvider>(
          builder: (context, provider, _) {
            final izinOnly = provider.combinedData
                .where(
                  (item) =>
                      item.jenis == JenisRiwayatGabungan.izin &&
                      item.izin != null,
                )
                .map((item) => item.izin!)
                .toList();
            final visibleItems = izinOnly.take(_visibleCount).toList();
            final hasMore = _visibleCount < izinOnly.length;

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
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
                      Text(
                        tr(context, 'your_leave_history'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                if (provider.isLoading && izinOnly.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const _IzinShimmerList(),
                      ]),
                    ),
                  )
                else if (izinOnly.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
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
                                  tr(context, 'no_history_yet'),
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
                        ),
                      ]),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: visibleItems.length + (hasMore ? 1 : 0) + 1,
                      itemBuilder: (context, index) {
                        if (index == visibleItems.length && hasMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          );
                        }
                        if (index >= visibleItems.length) {
                          return const SizedBox(height: 24);
                        }
                        return KartuIzin(izin: visibleItems[index]);
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IzinShimmerList extends StatelessWidget {
  const _IzinShimmerList();

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
            ),
          ],
        ),
      ),
    );
  }
}
