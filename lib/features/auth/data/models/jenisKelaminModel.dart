import '../../domain/entities/jenisKelamin.dart';

class JenisKelaminModel extends JenisKelamin {
  const JenisKelaminModel({required super.id, required super.nama});

  /// Maps API JSON from `/api/genders` to [JenisKelaminModel].
  ///
  /// Expected response format:
  /// ```json
  /// { "id": 1, "name": "Laki-laki" }
  /// ```
  ///
  /// Also supports `nama`, `title`, and `label` as fallback keys.
  factory JenisKelaminModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = switch (rawId) {
      num value => value.toInt(),
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    String nama;
    if (json['name'] != null && (json['name'] as String).trim().isNotEmpty) {
      nama = (json['name'] as String).trim();
    } else if (json['nama'] != null &&
        (json['nama'] as String).trim().isNotEmpty) {
      nama = (json['nama'] as String).trim();
    } else if (json['title'] != null &&
        (json['title'] as String).trim().isNotEmpty) {
      nama = (json['title'] as String).trim();
    } else if (json['label'] != null &&
        (json['label'] as String).trim().isNotEmpty) {
      nama = (json['label'] as String).trim();
    } else {
      nama = '-';
    }

    return JenisKelaminModel(id: id, nama: nama);
  }
}
