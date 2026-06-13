import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE scans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone TEXT NOT NULL,
            label TEXT,
            file_path TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            note TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_scans_zone ON scans(zone)');
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

  Future<List<ScanRecord>> getScansByZone(String zone) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'scans',
      where: 'zone = ?',
      whereArgs: <Object?>[zone],
      orderBy: 'created_at DESC',
    );
    return rows.map(ScanRecord.fromMap).toList();
  }

  Future<List<ZoneSummary>> getZoneSummaries() async {
    final List<Map<String, Object?>> rows = await _database.rawQuery('''
      SELECT s1.zone AS zone,
             COUNT(*) AS count,
             MAX(s1.created_at) AS last_at,
             (SELECT s2.file_path FROM scans s2
                WHERE s2.zone = s1.zone
                ORDER BY s2.created_at DESC LIMIT 1) AS last_path
      FROM scans s1
      GROUP BY s1.zone
      ORDER BY last_at DESC
    ''');
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
