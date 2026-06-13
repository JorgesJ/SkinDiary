import 'package:flutter/material.dart';

/// Marco guia que se dibuja sobre la vista previa de la camara para ayudar
/// a encuadrar la zona del cuerpo siempre de forma parecida.
class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85,
          heightFactor: 0.7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white54, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
