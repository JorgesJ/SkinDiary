import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_record.dart';
import '../services/analysis_service.dart';

/// Analiza dos fotos de la misma zona, marca las manchas/lunares detectados y
/// compara los resultados. Experimental: es una estimacion, no un diagnostico.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, required this.a, required this.b});

  final ScanRecord a; // mas antigua
  final ScanRecord b; // mas reciente

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  ImageAnalysisResult? _resA;
  ImageAnalysisResult? _resB;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final List<ImageAnalysisResult> results = await Future.wait<ImageAnalysisResult>(
        <Future<ImageAnalysisResult>>[
          compute(analyzeImageFile, widget.a.filePath),
          compute(analyzeImageFile, widget.b.filePath),
        ],
      );
      if (!mounted) return;
      setState(() {
        _resA = results[0];
        _resB = results[1];
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analizando imagenes...'),
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
    final ImageAnalysisResult a = _resA!;
    final ImageAnalysisResult b = _resB!;
    final DateFormat df = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        _SummaryCard(a: a, b: b),
        const SizedBox(height: 12),
        _Disclaimer(),
        const SizedBox(height: 12),
        _AnalyzedImage(
          label: 'Antes - ${df.format(widget.a.createdAt)}',
          path: widget.a.filePath,
          result: a,
        ),
        const SizedBox(height: 16),
        _AnalyzedImage(
          label: 'Despues - ${df.format(widget.b.createdAt)}',
          path: widget.b.filePath,
          result: b,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.a, required this.b});

  final ImageAnalysisResult a;
  final ImageAnalysisResult b;

  @override
  Widget build(BuildContext context) {
    final int diff = b.spotCount - a.spotCount;
    final String diffText = diff == 0
        ? 'sin cambios en el numero'
        : (diff > 0 ? '+$diff marca(s)' : '$diff marca(s)');
    final double pa = a.pigmentRatio * 100;
    final double pb = b.pigmentRatio * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Resultado', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(context, 'Marcas detectadas',
                '${a.spotCount}  ->  ${b.spotCount}   ($diffText)'),
            const SizedBox(height: 8),
            _row(context, 'Zona pigmentada',
                '${pa.toStringAsFixed(2)}%  ->  ${pb.toStringAsFixed(2)}%'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: diff > 0
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    diff > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
                    color: diff > 0 ? Colors.orange[800] : Colors.green[700],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      diff > 0
                          ? 'Se han detectado mas marcas que en la foto anterior. '
                              'Revisalo con tu especialista.'
                          : 'No se aprecian mas marcas que en la foto anterior.',
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

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 2, child: Text(label)),
        Expanded(
          flex: 3,
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
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
        'piel y las cuenta; el resultado depende mucho de la iluminacion y de '
        'que ambas fotos esten encuadradas igual. NO es un diagnostico: '
        'consulta siempre con tu especialista.',
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
  bool shouldRepaint(_SpotsPainter oldDelegate) =>
      oldDelegate.spots != spots;
}
