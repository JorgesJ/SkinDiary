import 'package:flutter/material.dart';

import '../services/consent_service.dart';
import 'profiles_screen.dart';

/// Aviso obligatorio al primer inicio: la app es informativa, sin validez medica.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _checked = false;

  Future<void> _accept() async {
    await ConsentService.setAccepted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ProfilesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 24),
              Icon(
                Icons.health_and_safety_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Aviso importante',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Esta aplicacion es de uso informativo y NO tiene ninguna '
                    'validez medica. Sirve unicamente para que puedas '
                    'documentar y comparar fotografias de tu piel a lo largo '
                    'del tiempo.\n\n'
                    'No realiza diagnosticos ni sustituye la valoracion de un '
                    'profesional. Para obtener un resultado verificado acude a '
                    'tu especialista.\n\n'
                    'Las imagenes se guardan en tu dispositivo. Eres '
                    'responsable de su custodia y privacidad.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              CheckboxListTile(
                value: _checked,
                onChanged: (bool? v) => setState(() => _checked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'He leido y acepto. Entiendo que no es una herramienta medica.',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _checked ? _accept : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Aceptar y continuar'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
