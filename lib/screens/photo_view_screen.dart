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
