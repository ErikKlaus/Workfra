import '../../domain/entities/batch.dart';

class BatchModel extends Batch {
  const BatchModel({required super.id, required super.name});

  /// Maps the actual API JSON from `/api/batches` to [BatchModel].
  ///
  /// The API returns `batch_ke` (e.g., "2", "3") instead of `name`.
  /// We construct a human-readable label like "Batch 2".
  factory BatchModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();

    String name;
    if (json['name'] != null && (json['name'] as String).trim().isNotEmpty) {
      name = (json['name'] as String).trim();
    } else if (json['batch_ke'] != null) {
      name = 'Batch ${json['batch_ke']}';
    } else {
      name = 'Batch $id';
    }

    return BatchModel(id: id, name: name);
  }
}
