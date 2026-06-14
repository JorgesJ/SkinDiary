import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/profile.dart';
import '../models/scan_record.dart';

/// Acceso a almacenamiento local: base de datos (metadatos) + ficheros (imagenes).
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final String dbDir = await getDatabasesPath();
    final String dbPath = p.join(dbDir, 'skin_diary.db');
    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            relation TEXT,
            color INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE scans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER,
            zone TEXT NOT NULL,
            label TEXT,
            file_path TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            note TEXT
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_scans_profile_zone ON scans(profile_id, zone)');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Anadimos perfiles y asociamos las fotos existentes a uno por defecto.
          await db.execute('''
            CREATE TABLE profiles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              relation TEXT,
              color INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('ALTER TABLE scans ADD COLUMN profile_id INTEGER');
          final int defaultId = await db.insert('profiles', <String, Object?>{
            'name': 'General',
            'relation': null,
            'color': 0xFF2E7D6B,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
          await db.update('scans', <String, Object?>{'profile_id': defaultId});
          await db.execute(
              'CREATE INDEX idx_scans_profile_zone ON scans(profile_id, zone)');
        }
      },
    );
  }

  Database get _database {
    final Database? db = _db;
    if (db == null) {
      throw StateError('StorageService no inicializado. Llama a init() primero.');
    }
    return db;
  }

  // ----------------------- Perfiles -----------------------

  Future<int> insertProfile(Profile profile) {
    return _database.insert('profiles', profile.toMap());
  }

  Future<List<Profile>> getProfiles() async {
    final List<Map<String, Object?>> rows = await _database.query(
      'profiles',
      orderBy: 'created_at ASC',
    );
    return rows.map(Profile.fromMap).toList();
  }

  Future<void> updateProfile(Profile profile) async {
    final int? id = profile.id;
    if (id == null) return;
    await _database.update('profiles', profile.toMap(),
        where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Elimina un perfil junto con todas sus fotos (registros + ficheros).
  Future<void> deleteProfile(int profileId) async {
    final List<ScanRecord> scans = await _database
        .query('scans', where: 'profile_id = ?', whereArgs: <Object?>[profileId])
        .then((List<Map<String, Object?>> rows) =>
            rows.map(ScanRecord.fromMap).toList());
    for (final ScanRecord s in scans) {
      final File f = File(s.filePath);
      if (await f.exists()) await f.delete();
    }
    await _database
        .delete('scans', where: 'profile_id = ?', whereArgs: <Object?>[profileId]);
    await _database
        .delete('profiles', where: 'id = ?', whereArgs: <Object?>[profileId]);
  }

  // ----------------------- Imagenes / scans -----------------------

  Future<Directory> _imagesDir() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(docs.path, 'scans'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copia la imagen capturada (ruta temporal) a almacenamiento permanente
  /// y devuelve la nueva ruta.
  Future<String> persistImage(String tempPath) async {
    final Directory dir = await _imagesDir();
    final String ext =
        p.extension(tempPath).isEmpty ? '.jpg' : p.extension(tempPath);
    final String fileName =
        'scan_${DateTime.now().millisecondsSinceEpoch}$ext';
    final String newPath = p.join(dir.path, fileName);
    await File(tempPath).copy(newPath);
    return newPath;
  }

  Future<int> insertScan(ScanRecord scan) {
    return _database.insert('scans', scan.toMap());
  }

  Future<List<ScanRecord>> getScansByZone(int profileId, String zone) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'scans',
      where: 'profile_id = ? AND zone = ?',
      whereArgs: <Object?>[profileId, zone],
      orderBy: 'created_at DESC',
    );
    return rows.map(ScanRecord.fromMap).toList();
  }

  Future<List<ZoneSummary>> getZoneSummaries(int profileId) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery('''
      SELECT s1.zone AS zone,
             COUNT(*) AS count,
             MAX(s1.created_at) AS last_at,
             (SELECT s2.file_path FROM scans s2
                WHERE s2.zone = s1.zone AND s2.profile_id = ?
                ORDER BY s2.created_at DESC LIMIT 1) AS last_path
      FROM scans s1
      WHERE s1.profile_id = ?
      GROUP BY s1.zone
      ORDER BY last_at DESC
    ''', <Object?>[profileId, profileId]);
    return rows
        .map((Map<String, Object?> r) => ZoneSummary(
              zone: r['zone'] as String,
              count: r['count'] as int,
              lastAt:
                  DateTime.fromMillisecondsSinceEpoch(r['last_at'] as int),
              lastPath: r['last_path'] as String?,
            ))
        .toList();
  }

  /// Numero total de fotos de un perfil (para mostrarlo en la lista de perfiles).
  Future<int> countScansForProfile(int profileId) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      'SELECT COUNT(*) AS c FROM scans WHERE profile_id = ?',
      <Object?>[profileId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> deleteScan(ScanRecord scan) async {
    final int? id = scan.id;
    if (id == null) return;
    await _database.delete('scans', where: 'id = ?', whereArgs: <Object?>[id]);
    final File file = File(scan.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
