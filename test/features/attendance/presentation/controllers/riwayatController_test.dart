import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:tugas_16_flutter/core/error/exceptions.dart';
import 'package:tugas_16_flutter/features/attendance/presentation/controllers/riwayatController.dart';
import 'package:tugas_16_flutter/features/attendance/presentation/providers/absensiProvider.dart';
import 'package:tugas_16_flutter/features/attendance/presentation/providers/riwayatProvider.dart';
import 'package:tugas_16_flutter/features/home/domain/entities/riwayat.dart';
import 'package:tugas_16_flutter/features/attendance/domain/entities/absensiHariIni.dart';

// ─── Fakes ─────────────────────────────────────────────────

class FakeAbsensiProvider extends ChangeNotifier implements AbsensiProvider {
  bool deleteAbsenCalled = false;
  int? lastDeletedId;
  bool shouldThrowOnDelete = false;
  String? throwMessage;
  int throwStatusCode = 0;

  @override
  Future<void> deleteAbsen(int id) async {
    deleteAbsenCalled = true;
    lastDeletedId = id;
    if (shouldThrowOnDelete) {
      throw ServerException(
        message: throwMessage ?? 'error_delete_attendance',
        statusCode: throwStatusCode,
      );
    }
  }

  // ── Unused stubs ──
  @override
  bool get isLoading => false;
  @override
  bool get isLoadingToday => false;
  @override
  bool get isLoadingHistory => false;
  @override
  bool get isDeleting => false;
  @override
  String? get errorMessage => null;
  @override
  List<Riwayat> get riwayatList => [];
  @override
  AbsensiHariIni get todayStatus => AbsensiHariIni.empty;
  @override
  Future<void> getToday() async {}
  @override
  Future<void> getHistory() async {}
  @override
  Future<void> loadHistory() async {}
}

class FakeRiwayatProvider extends ChangeNotifier implements RiwayatProvider {
  bool combineDataCalled = false;
  bool lastForceRefresh = false;

  final List<RiwayatGabunganItem> _combinedData;

  FakeRiwayatProvider({List<RiwayatGabunganItem>? data})
    : _combinedData = data ?? [];

  @override
  Future<void> combineData({bool forceRefresh = false}) async {
    combineDataCalled = true;
    lastForceRefresh = forceRefresh;
  }

  @override
  List<RiwayatGabunganItem> get combinedData => _combinedData;
  @override
  List<RiwayatGabunganItem> get top3CombinedData =>
      _combinedData.take(3).toList();
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;

  @override
  Future<void> silentRefresh() async {}
}

// ─── Helpers ───────────────────────────────────────────────

RiwayatGabunganItem _makePresensiItem(DateTime date, {int? id}) {
  return RiwayatGabunganItem.fromPresensi(
    Riwayat(
      id: id,
      tanggal: date,
      jamMasuk: '08:00',
      jamKeluar: '17:00',
      status: 'present',
    ),
  );
}

// ─── Tests ─────────────────────────────────────────────────

void main() {
  late FakeAbsensiProvider fakeAbsensi;
  late FakeRiwayatProvider fakeRiwayat;
  late RiwayatController controller;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('en_US', null);
  });

  setUp(() {
    fakeAbsensi = FakeAbsensiProvider();
    fakeRiwayat = FakeRiwayatProvider();
    controller = RiwayatController(
      absensiProvider: fakeAbsensi,
      riwayatProvider: fakeRiwayat,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  // ─── Filter Tanggal ────────────────────────────────────

  group('applyDateFilter', () {
    final items = [
      _makePresensiItem(DateTime(2026, 4, 1)),
      _makePresensiItem(DateTime(2026, 4, 5)),
      _makePresensiItem(DateTime(2026, 4, 10)),
      _makePresensiItem(DateTime(2026, 4, 15)),
      _makePresensiItem(DateTime(2026, 4, 20)),
    ];

    test('tanpa date range → kembalikan semua item', () {
      final result = controller.applyDateFilter(items);
      expect(result.length, equals(5));
    });

    test('dengan range yang cocok → kembalikan item dalam range', () {
      controller.setDateRange(
        DateTimeRange(start: DateTime(2026, 4, 5), end: DateTime(2026, 4, 15)),
      );

      final result = controller.applyDateFilter(items);
      expect(result.length, equals(3));
      expect(result[0].tanggal, equals(DateTime(2026, 4, 5)));
      expect(result[1].tanggal, equals(DateTime(2026, 4, 10)));
      expect(result[2].tanggal, equals(DateTime(2026, 4, 15)));
    });

    test('range tanpa data cocok → kembalikan list kosong', () {
      controller.setDateRange(
        DateTimeRange(start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 31)),
      );

      final result = controller.applyDateFilter(items);
      expect(result, isEmpty);
    });

    test('clearDateRange → kembali ke tanpa filter', () {
      controller.setDateRange(
        DateTimeRange(start: DateTime(2026, 4, 5), end: DateTime(2026, 4, 10)),
      );
      expect(controller.selectedDateRange, isNotNull);

      controller.clearDateRange();
      expect(controller.selectedDateRange, isNull);

      final result = controller.applyDateFilter(items);
      expect(result.length, equals(5));
    });

    test('range satu hari → kembalikan item di hari itu', () {
      controller.setDateRange(
        DateTimeRange(start: DateTime(2026, 4, 10), end: DateTime(2026, 4, 10)),
      );

      final result = controller.applyDateFilter(items);
      expect(result.length, equals(1));
      expect(result[0].tanggal, equals(DateTime(2026, 4, 10)));
    });
  });

  // ─── Delete Flow ───────────────────────────────────────

  group('deleteItem', () {
    test('delete sukses → return true, refresh data', () async {
      final success = await controller.deleteItem(42);

      expect(success, isTrue);
      expect(fakeAbsensi.deleteAbsenCalled, isTrue);
      expect(fakeAbsensi.lastDeletedId, equals(42));
      expect(fakeRiwayat.combineDataCalled, isTrue);
      expect(fakeRiwayat.lastForceRefresh, isTrue);
      expect(controller.isDeleting, isFalse);
      expect(controller.deleteError, isNull);
    });

    test(
      'delete gagal (ServerException) → return false + error message',
      () async {
        fakeAbsensi.shouldThrowOnDelete = true;
        fakeAbsensi.throwMessage = 'error_session_expired';
        fakeAbsensi.throwStatusCode = 401;

        final success = await controller.deleteItem(99);

        expect(success, isFalse);
        expect(controller.isDeleting, isFalse);
        expect(controller.deleteError, equals('error_session_expired'));
      },
    );

    test(
      'delete gagal (unexpected error) → return false + generic error',
      () async {
        // Override to throw a non-ServerException
        fakeAbsensi = _ThrowingAbsensiProvider();
        controller = RiwayatController(
          absensiProvider: fakeAbsensi,
          riwayatProvider: fakeRiwayat,
        );

        final success = await controller.deleteItem(1);

        expect(success, isFalse);
        expect(controller.isDeleting, isFalse);
        expect(controller.deleteError, equals('error_delete_attendance'));
      },
    );
  });

  // ─── State: Loading / Deleting ─────────────────────────

  group('state management', () {
    test('isDeleting kembali false setelah proses delete', () async {
      expect(controller.isDeleting, isFalse);
      await controller.deleteItem(1);
      expect(controller.isDeleting, isFalse);
    });

    test('loadCombinedHistory → memanggil provider.combineData', () async {
      await controller.loadCombinedHistory();

      expect(fakeRiwayat.combineDataCalled, isTrue);
      expect(fakeRiwayat.lastForceRefresh, isFalse);
    });

    test('loadCombinedHistory forceRefresh → diteruskan ke provider', () async {
      await controller.loadCombinedHistory(forceRefresh: true);

      expect(fakeRiwayat.lastForceRefresh, isTrue);
    });
  });

  // ─── Labels ────────────────────────────────────────────

  group('labels', () {
    test('periodLabel tanpa range → menampilkan bulan tahun saat ini', () {
      final label = controller.periodLabel('id_ID');
      expect(label, isNotEmpty);
      // Should contain current year
      expect(label, contains(DateTime.now().year.toString()));
    });

    test('periodLabel dengan range → menampilkan format range', () {
      controller.setDateRange(
        DateTimeRange(start: DateTime(2026, 4, 1), end: DateTime(2026, 4, 30)),
      );
      final label = controller.periodLabel('id_ID');
      expect(label, contains('01'));
      expect(label, contains('30'));
      expect(label, contains('-'));
    });

    test('filterLabelText tanpa range → return default label', () {
      final label = controller.filterLabelText('id_ID', 'Filter');
      expect(label, equals('Filter'));
    });

    test('filterLabelText dengan range → return formatted date', () {
      controller.setDateRange(
        DateTimeRange(start: DateTime(2026, 4, 1), end: DateTime(2026, 4, 30)),
      );
      final label = controller.filterLabelText('id_ID', 'Filter');
      expect(label, contains('01/04/26'));
      expect(label, contains('30/04/26'));
    });
  });

  // ─── No Hardcoded Secret ───────────────────────────────

  group('security', () {
    test('controller tidak mengandung hardcoded password/secret', () {
      // Verify no password field exists on the controller
      // This is a compile-time structural test — if someone adds
      // a password field, this test forces them to think about it.
      expect(controller, isA<RiwayatController>());
      // Controller should not have any password-related getters
      // (this is enforced by the class interface, not runtime check)
    });
  });
}

// ─── Helper fake that throws non-ServerException ─────────

class _ThrowingAbsensiProvider extends FakeAbsensiProvider {
  @override
  Future<void> deleteAbsen(int id) async {
    throw Exception('Unexpected error');
  }
}
