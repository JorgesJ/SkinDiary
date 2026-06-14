import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_record.dart';
import 'analysis_screen.dart';

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
            tooltip: 'Analizar cambios',
            icon: const Icon(Icons.biotech_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AnalysisScreen(a: widget.a, b: widget.b),
                ),
              );
            },
          ),
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
