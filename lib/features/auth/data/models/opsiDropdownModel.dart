import '../../domain/entities/opsiDropdown.dart';

class OpsiDropdownModel extends OpsiDropdown {
  const OpsiDropdownModel({required super.id, required super.nama});

  /// Maps API JSON to [OpsiDropdownModel].
  ///
  /// Supported label keys (checked in order):
  ///   1. `name`
  ///   2. `title`        – used by /api/trainings
  ///   3. `batch_ke`     – used by /api/batches  (prefixed to `"Batch <n>"`)
  ///   4. `nama`
  ///
  /// Falls back to '-' only when ALL keys are absent or null.
  factory OpsiDropdownModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = switch (rawId) {
      num value => value.toInt(),
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    // Resolve the display label from the most specific key available.
    String label;
    if (json['name'] != null && (json['name'] as String).trim().isNotEmpty) {
      label = (json['name'] as String).trim();
    } else if (json['title'] != null &&
        (json['title'] as String).trim().isNotEmpty) {
      label = (json['title'] as String).trim();
    } else if (json['batch_ke'] != null) {
      // batch_ke is typically a number string like "2", "3", etc.
      label = 'Batch ${json['batch_ke']}';
    } else if (json['nama'] != null &&
        (json['nama'] as String).trim().isNotEmpty) {
      label = (json['nama'] as String).trim();
    } else {
      label = '-';
    }

    return OpsiDropdownModel(id: id, nama: label);
  }
}
