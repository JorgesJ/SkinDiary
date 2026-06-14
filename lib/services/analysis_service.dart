import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Una marca detectada (lunar, mancha, peca...) en coordenadas normalizadas
/// (0..1) respecto al ancho/alto de la imagen, para poder dibujarla a cualquier
/// tamano en pantalla.
class DetectedSpot {
  DetectedSpot({required this.cx, required this.cy, required this.r});

  final double cx; // centro X (0..1)
  final double cy; // centro Y (0..1)
  final double r; // radio aproximado, normalizado respecto al ancho

  Map<String, double> toMap() => <String, double>{'cx': cx, 'cy': cy, 'r': r};

  factory DetectedSpot.fromMap(Map<String, double> m) =>
      DetectedSpot(cx: m['cx']!, cy: m['cy']!, r: m['r']!);
}

/// Resultado del analisis de una imagen.
class ImageAnalysisResult {
  ImageAnalysisResult({
    required this.spotCount,
    required this.pigmentRatio,
    required this.aspect,
    required this.spots,
  });

  /// Numero de marcas detectadas.
  final int spotCount;

  /// Fraccion de la imagen ocupada por marcas (0..1).
  final double pigmentRatio;

  /// Relacion de aspecto (ancho/alto) de la imagen.
  final double aspect;

  final List<DetectedSpot> spots;
}

/// Punto de entrada para `compute`: analiza la imagen del path indicado.
/// Es una funcion de nivel superior para poder ejecutarse en un isolate.
ImageAnalysisResult analyzeImageFile(String path) {
  final Uint8List bytes = File(path).readAsBytesSync();
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return ImageAnalysisResult(
        spotCount: 0, pigmentRatio: 0, aspect: 1, spots: <DetectedSpot>[]);
  }
  // Respeta la orientacion EXIF.
  decoded = img.bakeOrientation(decoded);
  final double aspect = decoded.width / decoded.height;

  // Reducimos para que el analisis sea rapido.
  const int targetWidth = 480;
  final img.Image small = decoded.width > targetWidth
      ? img.copyResize(decoded, width: targetWidth)
      : decoded;

  final int w = small.width;
  final int h = small.height;
  final int n = w * h;

  // 1) Escala de grises.
  final Uint8List gray = Uint8List(n);
  final Uint8List rgb = small.getBytes(order: img.ChannelOrder.rgb);
  for (int i = 0; i < n; i++) {
    final int o = i * 3;
    final int r = rgb[o];
    final int g = rgb[o + 1];
    final int b = rgb[o + 2];
    gray[i] = (0.299 * r + 0.587 * g + 0.114 * b).round();
  }

  // 2) Imagen integral para calcular la media local rapido.
  final Int32List integral = Int32List((w + 1) * (h + 1));
  for (int y = 0; y < h; y++) {
    int rowSum = 0;
    for (int x = 0; x < w; x++) {
      rowSum += gray[y * w + x];
      integral[(y + 1) * (w + 1) + (x + 1)] =
          integral[y * (w + 1) + (x + 1)] + rowSum;
    }
  }

  int areaSum(int x0, int y0, int x1, int y1) {
    final int a = integral[y1 * (w + 1) + x1];
    final int b = integral[y0 * (w + 1) + x1];
    final int c = integral[y1 * (w + 1) + x0];
    final int d = integral[y0 * (w + 1) + x0];
    return a - b - c + d;
  }

  // 3) Umbral adaptativo: una marca es notablemente mas oscura que su entorno.
  final int rad = (w / 12).round().clamp(6, 40);
  const double delta = 14; // cuanto mas oscuro que la media local
  final Uint8List mask = Uint8List(n);
  for (int y = 0; y < h; y++) {
    final int y0 = (y - rad).clamp(0, h);
    final int y1 = (y + rad + 1).clamp(0, h);
    for (int x = 0; x < w; x++) {
      final int x0 = (x - rad).clamp(0, w);
      final int x1 = (x + rad + 1).clamp(0, w);
      final int count = (x1 - x0) * (y1 - y0);
      final double mean = areaSum(x0, y0, x1, y1) / count;
      mask[y * w + x] = (gray[y * w + x] < mean - delta) ? 1 : 0;
    }
  }

  // 4) Componentes conexas (8-conectividad) con BFS.
  final Uint8List visited = Uint8List(n);
  final List<int> queue = <int>[];
  final List<DetectedSpot> spots = <DetectedSpot>[];

  final int minArea = (n * 0.00004).round().clamp(4, 1 << 30);
  final double maxArea = n * 0.03;
  int totalSpotArea = 0;

  for (int start = 0; start < n; start++) {
    if (mask[start] == 0 || visited[start] == 1) continue;
    queue
      ..clear()
      ..add(start);
    visited[start] = 1;
    int area = 0;
    int sumX = 0, sumY = 0;
    int minX = w, minY = h, maxX = 0, maxY = 0;

    while (queue.isNotEmpty) {
      final int p = queue.removeLast();
      final int px = p % w;
      final int py = p ~/ w;
      area++;
      sumX += px;
      sumY += py;
      if (px < minX) minX = px;
      if (py < minY) minY = py;
      if (px > maxX) maxX = px;
      if (py > maxY) maxY = py;

      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final int nx = px + dx;
          final int ny = py + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final int np = ny * w + nx;
          if (mask[np] == 1 && visited[np] == 0) {
            visited[np] = 1;
            queue.add(np);
          }
        }
      }
    }

    if (area < minArea || area > maxArea) continue;
    // Filtro de "compacidad": descarta sombras alargadas/irregulares.
    final int bboxW = (maxX - minX + 1);
    final int bboxH = (maxY - minY + 1);
    final double fill = area / (bboxW * bboxH);
    if (fill < 0.30) continue;

    totalSpotArea += area;
    final double cx = (sumX / area) / w;
    final double cy = (sumY / area) / h;
    final double rNorm = math.sqrt(area / math.pi) / w;
    spots.add(DetectedSpot(cx: cx, cy: cy, r: rNorm));
  }

  // Limitamos para no saturar el dibujado.
  spots.sort((DetectedSpot a, DetectedSpot b) => b.r.compareTo(a.r));
  final List<DetectedSpot> limited =
      spots.length > 250 ? spots.sublist(0, 250) : spots;

  return ImageAnalysisResult(
    spotCount: spots.length,
    pigmentRatio: totalSpotArea / n,
    aspect: aspect,
    spots: limited,
  );
}
