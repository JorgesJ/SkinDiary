/// Representa una foto guardada de una zona del cuerpo.
class ScanRecord {
  ScanRecord({
    this.id,
    this.profileId,
    required this.zone,
    this.label,
    required this.filePath,
    required this.createdAt,
    this.note,
  });

  final int? id;
  final int? profileId;
  final String zone;
  final String? label;
  final String filePath;
  final DateTime createdAt;
  final String? note;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'profile_id': profileId,
      'zone': zone,
      'label': label,
      'file_path': filePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory ScanRecord.fromMap(Map<String, Object?> map) {
    return ScanRecord(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int?,
      zone: map['zone'] as String,
      label: map['label'] as String?,
      filePath: map['file_path'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      note: map['note'] as String?,
    );
  }
}

/// Resumen de una zona del cuerpo (para la pantalla principal).
class ZoneSummary {
  ZoneSummary({
    required this.zone,
    required this.count,
    required this.lastAt,
    this.lastPath,
  });

  final String zone;
  final int count;
  final DateTime lastAt;
  final String? lastPath;
}
