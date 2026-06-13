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
