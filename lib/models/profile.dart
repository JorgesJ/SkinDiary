/// Perfil de una persona (p. ej. "Yo", "Hijo"). Cada foto pertenece a un perfil.
class Profile {
  Profile({
    this.id,
    required this.name,
    this.relation,
    required this.colorValue,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? relation;

  /// Color del avatar guardado como entero ARGB (ej: 0xFF2E7D6B).
  final int colorValue;
  final DateTime createdAt;

  /// Inicial para mostrar en el avatar.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'relation': relation,
      'color': colorValue,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Profile.fromMap(Map<String, Object?> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      relation: map['relation'] as String?,
      colorValue: map['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
