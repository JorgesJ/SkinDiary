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
            child: Image.file(File(ghost!), fit: BoxFit.cover),
          ),
        const CameraOverlay(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Consejo: coloca un fondo liso y oscuro detras de la zona '
                'para evitar marcas falsas en el analisis.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
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
      padding: EdgeInsets.fromLTRB(
          12, 16, 12, 16 + MediaQuery.of(context).padding.bottom),
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
