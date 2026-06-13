# SkinDiary — Briefing completo para construir la app

> **Pega este documento entero en el otro chat.** Contiene la especificacion y el
> codigo fuente completo de la app. El objetivo es que la app quede igual que lo
> que ya hemos disenado.

---

## 0. REGLA CRITICA

**Quiero una app NATIVA hecha con FLUTTER (Dart). NO una WebView, NO una web
empaquetada.** Un unico codigo fuente que sirve para **Android (primero)** e
**iOS (despues)** sin reescribir nada.

Si en el repositorio ya existe una version WebView o web, **hay que sustituirla**
por este proyecto Flutter nativo.

Motivo: una WebView da problemas serios con el acceso a la **camara** y al
**almacenamiento local**, que son el nucleo de esta app.

---

## 1. Concepto

App para **documentar y comparar fotografias de mi piel** a lo largo del tiempo
(lunares, manchas, pecas, verrugas), organizadas por zona del cuerpo. Me lo ha
pedido el dermatologo para vigilar la evolucion (manchas nuevas, lunares que
crecen o cambian, etc.).

Es una herramienta de **documentacion y seguimiento**, NO de diagnostico.

---

## 2. Decisiones tecnicas (ya tomadas)

- **Framework:** Flutter (Dart). Desarrollo en Android Studio.
- **Plataformas:** Android primero (tengo cuenta de Play Console). iOS mas
  adelante con el MISMO codigo.
- **Almacenamiento:** 100% local en el dispositivo. Nada se sube a internet.
  - SQLite (`sqflite`) para los metadatos.
  - Ficheros en el directorio de documentos de la app para las imagenes.
- **Nombre de la app (visible):** SkinDiary
- **Nombre del paquete (pubspec):** `skin_diary`

### Dependencias
`camera`, `path_provider`, `path`, `shared_preferences`, `sqflite`,
`permission_handler`, `intl`.

---

## 3. Aviso legal obligatorio (pantalla de consentimiento al primer inicio)

Al abrir la app por primera vez debe aparecer un aviso con este texto y un
checkbox de aceptacion que se guarda (con `shared_preferences`):

> "Esta aplicacion es de uso informativo, no tiene ninguna validez medica. Para
> tener un resultado verificado acude a tu especialista."

Hasta que no se acepte, no se entra a la app.

---

## 4. Funcionalidades del MVP (Fase 1)

1. **Consentimiento** al primer arranque (persistido).
2. **Pantalla principal:** lista de zonas del cuerpo con miniatura de la ultima
   foto, numero de fotos y fecha de la ultima.
3. **Captura con camara:** marco-guia en pantalla + superposicion "fantasma" de
   la foto anterior con control de opacidad (para encuadrar igual cada vez).
   Nota opcional por foto.
4. **Galeria por zona:** todas las fotos de esa zona ordenadas por fecha (grid).
5. **Comparacion:** seleccionar 2 fotos de la misma zona y verlas **lado a lado**
   o con un **deslizador (slider)**, mostrando los dias transcurridos.
6. **Visor** a pantalla completa con zoom y opcion de borrar.

### Fases futuras (no ahora)
- **Fase 2:** recordatorios periodicos, exportar a PDF/zip para el dermatologo,
  copia de seguridad cifrada.
- **Fase 3:** deteccion/medicion automatica de lunares con vision por computador.

---

## 5. Puesta en marcha (para Android Studio)

El proyecto contiene `lib/` y `pubspec.yaml`. Las carpetas de plataforma se
generan con:

```bash
flutter create .      # genera android/ ios/ etc. sin tocar lib/
flutter pub get
flutter run
```

### Permisos de camara
- **Android** (`android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`):
  `<uses-permission android:name="android.permission.CAMERA" />`
  y `minSdkVersion 21` en `android/app/build.gradle`.
- **iOS** (`ios/Runner/Info.plist`):
  clave `NSCameraUsageDescription` con un texto explicativo.

---

## 6. Estructura del proyecto

```
lib/
  main.dart                 # arranque: camaras + BD + consentimiento
  app_theme.dart
  data/body_zones.dart
  models/scan_record.dart
  services/storage_service.dart
  services/consent_service.dart
  screens/consent_screen.dart
  screens/home_screen.dart
  screens/zone_detail_screen.dart
  screens/capture_screen.dart
  screens/photo_view_screen.dart
  screens/compare_screen.dart
  widgets/camera_overlay.dart
pubspec.yaml
analysis_options.yaml
```

---

## 7. CODIGO FUENTE COMPLETO

Crea cada archivo con exactamente este contenido.

### pubspec.yaml
```yaml
name: skin_diary
description: "SkinDiary: seguimiento fotografico de la piel (lunares, manchas, pecas). Uso informativo, sin validez medica."
publish_to: "none"
version: 0.1.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  camera: ^0.11.0+2
  path_provider: ^2.1.4
  path: ^1.9.0
  shared_preferences: ^2.3.2
  sqflite: ^2.4.0
  permission_handler: ^11.3.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

### analysis_options.yaml
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    avoid_print: true
```

### lib/main.dart
```dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'services/consent_service.dart';
import 'services/storage_service.dart';

/// Camaras disponibles en el dispositivo. Se rellena en [main].
List<CameraDescription> cameras = <CameraDescription>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (_) {
    // El dispositivo/emulador puede no tener camara disponible.
    cameras = <CameraDescription>[];
  }

  await StorageService.instance.init();
  final bool accepted = await ConsentService.isAccepted();

  runApp(SkinDiaryApp(consentAccepted: accepted));
}

class SkinDiaryApp extends StatelessWidget {
  const SkinDiaryApp({super.key, required this.consentAccepted});

  final bool consentAccepted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinDiary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: consentAccepted ? const HomeScreen() : const ConsentScreen(),
    );
  }
}
```

### lib/app_theme.dart
```dart
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6B),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
```

### lib/data/body_zones.dart
```dart
/// Zonas del cuerpo sugeridas para organizar las capturas.
class BodyZones {
  const BodyZones._();

  static const List<String> defaults = <String>[
    'Brazo izquierdo',
    'Brazo derecho',
    'Antebrazo izquierdo',
    'Antebrazo derecho',
    'Hombro izquierdo',
    'Hombro derecho',
    'Espalda',
    'Pecho',
    'Abdomen',
    'Pierna izquierda',
    'Pierna derecha',
    'Mano izquierda',
    'Mano derecha',
    'Cuello',
    'Cara',
    'Cuero cabelludo',
    'Otro',
  ];
}
```

### lib/models/scan_record.dart
```dart
/// Representa una foto guardada de una zona del cuerpo.
class ScanRecord {
  ScanRecord({
    this.id,
    required this.zone,
    this.label,
    required this.filePath,
    required this.createdAt,
    this.note,
  });

  final int? id;
  final String zone;
  final String? label;
  final String filePath;
  final DateTime createdAt;
  final String? note;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
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
```

### lib/services/consent_service.dart
```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona si el usuario ha aceptado el aviso de uso informativo.
class ConsentService {
  const ConsentService._();

  static const String _key = 'consent_accepted_v1';

  static Future<bool> isAccepted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setAccepted(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
```

### lib/services/storage_service.dart
```dart
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
```

### lib/widgets/camera_overlay.dart
```dart
import 'package:flutter/material.dart';

/// Marco guia que se dibuja sobre la vista previa de la camara para ayudar
/// a encuadrar la zona del cuerpo siempre de forma parecida.
class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85,
          heightFactor: 0.7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white54, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
```

### lib/screens/consent_screen.dart
```dart
import 'package:flutter/material.dart';

import '../services/consent_service.dart';
import 'home_screen.dart';

/// Aviso obligatorio al primer inicio: la app es informativa, sin validez medica.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _checked = false;

  Future<void> _accept() async {
    await ConsentService.setAccepted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 24),
              Icon(
                Icons.health_and_safety_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Aviso importante',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Esta aplicacion es de uso informativo y NO tiene ninguna '
                    'validez medica. Sirve unicamente para que puedas '
                    'documentar y comparar fotografias de tu piel a lo largo '
                    'del tiempo.\n\n'
                    'No realiza diagnosticos ni sustituye la valoracion de un '
                    'profesional. Para obtener un resultado verificado acude a '
                    'tu especialista.\n\n'
                    'Las imagenes se guardan en tu dispositivo. Eres '
                    'responsable de su custodia y privacidad.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              CheckboxListTile(
                value: _checked,
                onChanged: (bool? v) => setState(() => _checked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'He leido y acepto. Entiendo que no es una herramienta medica.',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _checked ? _accept : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Aceptar y continuar'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
```

### lib/screens/home_screen.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/body_zones.dart';
import '../services/storage_service.dart';
import 'zone_detail_screen.dart';

/// Pantalla principal: lista de zonas del cuerpo con su ultima foto.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ZoneSummary>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = StorageService.instance.getZoneSummaries();
    });
  }

  Future<void> _pickZoneForNewScan() async {
    final String? zone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ZonePickerSheet(),
    );
    if (zone == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ZoneDetailScreen(zone: zone)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis zonas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickZoneForNewScan,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Nueva captura'),
      ),
      body: FutureBuilder<List<ZoneSummary>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<ZoneSummary>> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<ZoneSummary> zones = snap.data ?? <ZoneSummary>[];
          if (zones.isEmpty) {
            return _EmptyState(onStart: _pickZoneForNewScan);
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: zones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int i) {
                final ZoneSummary z = zones[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: _Thumb(path: z.lastPath),
                    title: Text(z.zone),
                    subtitle: Text(
                      '${z.count} foto(s) - ultima ${DateFormat('dd/MM/yyyy').format(z.lastAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ZoneDetailScreen(zone: z.zone),
                        ),
                      );
                      _refresh();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final String? path = this.path;
    final bool exists = path != null && File(path).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: exists
            ? Image.file(File(path), fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_outlined),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.photo_camera_back_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Aun no tienes capturas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera captura eligiendo una zona del cuerpo. '
              'Con el tiempo podras comparar la evolucion.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Empezar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonePickerSheet extends StatelessWidget {
  const _ZonePickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Elige una zona del cuerpo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final String zone in BodyZones.defaults)
                  ListTile(
                    leading: const Icon(Icons.accessibility_new),
                    title: Text(zone),
                    onTap: () => Navigator.of(context).pop(zone),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### lib/screens/zone_detail_screen.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_record.dart';
import '../services/storage_service.dart';
import 'capture_screen.dart';
import 'compare_screen.dart';
import 'photo_view_screen.dart';

/// Muestra todas las fotos de una zona y permite anadir o comparar.
class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({super.key, required this.zone});

  final String zone;

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  late Future<List<ScanRecord>> _future;
  final Set<int> _selected = <int>{};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = StorageService.instance.getScansByZone(widget.zone);
    });
  }

  Future<void> _newPhoto(List<ScanRecord> existing) async {
    final String? ghostPath =
        existing.isNotEmpty ? existing.first.filePath : null;
    final bool? captured = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CaptureScreen(zone: widget.zone, ghostPath: ghostPath),
      ),
    );
    if (captured == true) _refresh();
  }

  void _toggleSelect(ScanRecord s) {
    final int? id = s.id;
    if (id == null) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        if (_selected.length >= 2) {
          _selected.remove(_selected.first);
        }
        _selected.add(id);
      }
    });
  }

  Future<void> _openCompare() async {
    final List<ScanRecord> scans =
        await StorageService.instance.getScansByZone(widget.zone);
    final List<ScanRecord> selected = scans
        .where((ScanRecord s) => _selected.contains(s.id))
        .toList()
      ..sort((ScanRecord a, ScanRecord b) =>
          a.createdAt.compareTo(b.createdAt));
    if (selected.length != 2 || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompareScreen(a: selected.first, b: selected.last),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zone),
        actions: <Widget>[
          IconButton(
            tooltip: _selectMode ? 'Cancelar' : 'Comparar',
            icon: Icon(_selectMode ? Icons.close : Icons.compare),
            onPressed: () => setState(() {
              _selectMode = !_selectMode;
              _selected.clear();
            }),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<List<ScanRecord>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<ScanRecord>> snap) {
          final List<ScanRecord> list = snap.data ?? <ScanRecord>[];
          return FloatingActionButton.extended(
            onPressed: () => _newPhoto(list),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Nueva foto'),
          );
        },
      ),
      body: FutureBuilder<List<ScanRecord>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<ScanRecord>> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<ScanRecord> scans = snap.data ?? <ScanRecord>[];
          if (scans.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No hay fotos de esta zona todavia.\n'
                  'Pulsa "Nueva foto" para empezar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: scans.length,
            itemBuilder: (BuildContext context, int i) {
              final ScanRecord s = scans[i];
              final bool selected = _selected.contains(s.id);
              return GestureDetector(
                onTap: () {
                  if (_selectMode) {
                    _toggleSelect(s);
                  } else {
                    Navigator.of(context)
                        .push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => PhotoViewScreen(scan: s),
                      ),
                    )
                        .then((bool? deleted) {
                      if (deleted == true) _refresh();
                    });
                  }
                },
                onLongPress: () {
                  setState(() => _selectMode = true);
                  _toggleSelect(s);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: File(s.filePath).existsSync()
                          ? Image.file(File(s.filePath), fit: BoxFit.cover)
                          : Container(color: Colors.grey.shade300),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.black54,
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(s.createdAt),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (_selectMode)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white70,
                          child: Icon(
                            selected
                                ? Icons.check
                                : Icons.circle_outlined,
                            size: 16,
                            color: selected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _selectMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _selected.length == 2 ? _openCompare : null,
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(
                    _selected.length == 2
                        ? 'Comparar las 2 fotos'
                        : 'Selecciona 2 fotos (${_selected.length}/2)',
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
```

### lib/screens/capture_screen.dart
```dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart' show cameras;
import '../models/scan_record.dart';
import '../services/storage_service.dart';
import '../widgets/camera_overlay.dart';

/// Captura una foto de la zona con marco guia y, opcionalmente, la foto
/// anterior superpuesta ("fantasma") para alinear el mismo encuadre.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, required this.zone, this.ghostPath});

  final String zone;
  final String? ghostPath;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  bool _showGhost = true;
  double _ghostOpacity = 0.4;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final PermissionStatus status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _initializing = false;
        _error = 'Permiso de camara denegado. Habilitalo en los ajustes del '
            'telefono para poder tomar fotos.';
      });
      return;
    }
    if (cameras.isEmpty) {
      setState(() {
        _initializing = false;
        _error = 'No se ha encontrado ninguna camara en el dispositivo.';
      });
      return;
    }
    final CameraDescription back = cameras.firstWhere(
      (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final CameraController controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _initializing = false;
        _error = 'No se pudo iniciar la camara: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final XFile file = await controller.takePicture();
      final String permanentPath =
          await StorageService.instance.persistImage(file.path);
      if (!mounted) return;
      final String? note = await _askNote();
      await StorageService.instance.insertScan(
        ScanRecord(
          zone: widget.zone,
          filePath: permanentPath,
          createdAt: DateTime.now(),
          note: (note != null && note.isEmpty) ? null : note,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar: $e')),
      );
    }
  }

  Future<String?> _askNote() {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Nota (opcional)'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ej: lunar nuevo en la muneca',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('Sin nota'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.zone),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final CameraController controller = _controller!;
    final String? ghost = widget.ghostPath;
    final bool hasGhost = ghost != null && File(ghost).existsSync();
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(child: CameraPreview(controller)),
        if (hasGhost && _showGhost)
          Opacity(
            opacity: _ghostOpacity,
            child: Image.file(File(ghost), fit: BoxFit.cover),
          ),
        const CameraOverlay(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _controls(hasGhost),
        ),
      ],
    );
  }

  Widget _controls(bool hasGhost) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      color: Colors.black54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasGhost)
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    _showGhost ? Icons.layers : Icons.layers_clear,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _showGhost = !_showGhost),
                ),
                const Text(
                  'Guia foto anterior',
                  style: TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: Slider(
                    value: _ghostOpacity,
                    onChanged: _showGhost
                        ? (double v) => setState(() => _ghostOpacity = v)
                        : null,
                  ),
                ),
              ],
            ),
          GestureDetector(
            onTap: _busy ? null : _capture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white70, width: 4),
              ),
              child: _busy
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.camera_alt, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}
```

### lib/screens/photo_view_screen.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_record.dart';
import '../services/storage_service.dart';

/// Visor de una foto a pantalla completa con zoom y opcion de eliminar.
class PhotoViewScreen extends StatelessWidget {
  const PhotoViewScreen({super.key, required this.scan});

  final ScanRecord scan;

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text(
          'Seguro que quieres eliminar esta foto? No se puede deshacer.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.instance.deleteScan(scan);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('dd/MM/yyyy HH:mm');
    final bool hasNote = scan.note != null && scan.note!.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(scan.zone),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: File(scan.filePath).existsSync()
                    ? Image.file(File(scan.filePath))
                    : const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  df.format(scan.createdAt),
                  style: const TextStyle(color: Colors.white70),
                ),
                if (hasNote) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    scan.note!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### lib/screens/compare_screen.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_record.dart';

/// Compara dos fotos de la misma zona: lado a lado o con un deslizador.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.a, required this.b});

  /// Foto mas antigua.
  final ScanRecord a;

  /// Foto mas reciente.
  final ScanRecord b;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  bool _sliderMode = false;
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('dd/MM/yyyy');
    final int days =
        widget.b.createdAt.difference(widget.a.createdAt).inDays;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar'),
        actions: <Widget>[
          IconButton(
            tooltip: _sliderMode ? 'Lado a lado' : 'Deslizador',
            icon: Icon(_sliderMode ? Icons.view_column : Icons.compare),
            onPressed: () => setState(() => _sliderMode = !_sliderMode),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${df.format(widget.a.createdAt)}  ->  ${df.format(widget.b.createdAt)}'
              '${days > 0 ? '   ($days dias)' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: _sliderMode ? _buildSlider() : _buildSideBySide(df),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySide(DateFormat df) {
    return Row(
      children: <Widget>[
        Expanded(child: _imageWithLabel(widget.a, 'Antes', df)),
        const VerticalDivider(width: 1),
        Expanded(child: _imageWithLabel(widget.b, 'Despues', df)),
      ],
    );
  }

  Widget _imageWithLabel(ScanRecord s, String label, DateFormat df) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          color: Colors.black87,
          child: Text(
            '$label - ${df.format(s.createdAt)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: File(s.filePath).existsSync()
                  ? Image.file(File(s.filePath), fit: BoxFit.contain)
                  : const Icon(Icons.broken_image),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    final bool aExists = File(widget.a.filePath).existsSync();
    final bool bExists = File(widget.b.filePath).existsSync();
    return Column(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (bExists)
                    Image.file(File(widget.b.filePath), fit: BoxFit.contain),
                  ClipRect(
                    clipper: _SplitClipper(_split),
                    child: aExists
                        ? Image.file(File(widget.a.filePath),
                            fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    left: constraints.maxWidth * _split - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              const Text('Antes'),
              Expanded(
                child: Slider(
                  value: _split,
                  onChanged: (double v) => setState(() => _split = v),
                ),
              ),
              const Text('Despues'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  _SplitClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_SplitClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
```

---

## 8. Instruccion final para el otro chat

"Crea/sustituye el proyecto del repositorio por esta app Flutter nativa con
exactamente estos archivos y contenidos. NO uses WebView. Luego ejecuta
`flutter create .` para generar las carpetas de plataforma, anade el permiso de
camara y deja la app lista para compilar en Android Studio."
