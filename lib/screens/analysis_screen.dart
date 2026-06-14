import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_record.dart';
import '../services/analysis_service.dart';

/// Analiza 2 o mas fotos de la misma zona, marca las manchas/lunares
/// detectados y muestra la evolucion. Experimental: es una estimacion, no un
/// diagnostico.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, required this.scans});

  /// Fotos a analizar (se ordenan de la mas antigua a la mas reciente).
  final List<ScanRecord> scans;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late final List<ScanRecord> _ordered;
  List<ImageAnalysisResult>? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ordered = List<ScanRecord>.from(widget.scans)
      ..sort((ScanRecord a, ScanRecord b) =>
          a.createdAt.compareTo(b.createdAt));
    _run();
  }

  Future<void> _run() async {
    try {
      final List<ImageAnalysisResult> results =
          await Future.wait<ImageAnalysisResult>(
        _ordered.map((ScanRecord s) =>
            compute(analyzeImageFile, s.filePath)),
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo analizar: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis de cambios')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Analizando ${_ordered.length} foto(s)...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final List<ImageAnalysisResult> results = _results!;
    final DateFormat df = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        _TrendCard(scans: _ordered, results: results),
        const SizedBox(height: 12),
        _Disclaimer(),
        const SizedBox(height: 12),
        for (int i = 0; i < _ordered.length; i++) ...<Widget>[
          _AnalyzedImage(
            label: df.format(_ordered[i].createdAt),
            path: _ordered[i].filePath,
            result: results[i],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.scans, required this.results});

  final List<ScanRecord> scans;
  final List<ImageAnalysisResult> results;

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('dd/MM/yyyy');
    final int first = results.first.spotCount;
    final int last = results.last.spotCount;
    final int diff = last - first;
    final bool increased = diff > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Evolucion (${results.length} fotos)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (int i = 0; i < results.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(df.format(scans[i].createdAt)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('${results[i].spotCount} marca(s)',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${(results[i].pigmentRatio * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: increased
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    increased
                        ? Icons.trending_up
                        : Icons.check_circle_outline,
                    color: increased ? Colors.orange[800] : Colors.green[700],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      increased
                          ? 'De la primera a la ultima foto se detectan '
                              '$diff marca(s) mas. Revisalo con tu especialista.'
                          : 'No se aprecia aumento de marcas entre la primera '
                              'y la ultima foto.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Analisis experimental y orientativo. Detecta zonas mas oscuras que la '
        'piel y las cuenta; depende mucho de la iluminacion y de que las fotos '
        'esten encuadradas igual y con fondo liso y oscuro. NO es un '
        'diagnostico: consulta siempre con tu especialista.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}

class _AnalyzedImage extends StatelessWidget {
  const _AnalyzedImage({
    required this.label,
    required this.path,
    required this.result,
  });

  final String label;
  final String path;
  final ImageAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final bool exists = File(path).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label  -  ${result.spotCount} marca(s)',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: result.aspect <= 0 ? 1 : result.aspect,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: exists
                      ? Image.file(File(path), fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade300),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpotsPainter(result.spots),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotsPainter extends CustomPainter {
  _SpotsPainter(this.spots);

  final List<DetectedSpot> spots;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFF3D00);

    for (final DetectedSpot s in spots) {
      final Offset center = Offset(s.cx * size.width, s.cy * size.height);
      final double radius = (s.r * size.width).clamp(4.0, 60.0) + 3;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SpotsPainter oldDelegate) => oldDelegate.spots != spots;
}
