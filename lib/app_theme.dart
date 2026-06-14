import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  const AppTheme._();

  /// Estilo de barras del sistema para pantallas claras: iconos OSCUROS
  /// (status y navegacion) para que se vean sobre fondo claro.
  static const SystemUiOverlayStyle darkIconsOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Estilo para pantallas oscuras (camara, visor): iconos CLAROS.
  static const SystemUiOverlayStyle lightIconsOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6B),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        systemOverlayStyle: darkIconsOverlay,
      ),
    );
  }
}
