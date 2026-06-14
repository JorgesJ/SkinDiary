import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/body_zones.dart';
import '../models/profile.dart';
import '../models/scan_record.dart';
import '../services/storage_service.dart';
import 'zone_detail_screen.dart';

/// Lista de zonas del cuerpo de un perfil concreto, con su ultima foto.
class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  late Future<List<ZoneSummary>> _future;

  int get _profileId => widget.profile.id!;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = StorageService.instance.getZoneSummaries(_profileId);
    });
  }

  Future<void> _pickZoneForNewScan() async {
    final String? zone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ZonePickerSheet(),
    );
    if (zone == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ZoneDetailScreen(profile: widget.profile, zone: zone),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.profile.name)),
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
                          builder: (_) => ZoneDetailScreen(
                              profile: widget.profile, zone: z.zone),
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
            ? Image.file(File(path!), fit: BoxFit.cover)
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
              'Aun no hay capturas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea la primera captura eligiendo una zona del cuerpo. '
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
