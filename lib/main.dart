import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'services/consent_service.dart';
import 'services/storage_service.dart';

/// Camaras disponibles en el dispositivo. Se rellena en [main].
List<CameraDescription> cameras = <CameraDescription>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Barra de navegacion del sistema visible: fondo claro con iconos oscuros.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Color(0xFFE0E0E0),
  ));

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
