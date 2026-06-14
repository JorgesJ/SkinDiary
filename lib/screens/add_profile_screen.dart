import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/storage_service.dart';

/// Formulario para crear un nuevo perfil/usuario.
class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _relation = TextEditingController();
  bool _saving = false;

  static const List<int> _palette = <int>[
    0xFF2E7D6B,
    0xFF1565C0,
    0xFF6A1B9A,
    0xFFC62828,
    0xFFEF6C00,
    0xFF00838F,
    0xFF558B2F,
    0xFFAD1457,
  ];
  int _color = _palette.first;

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para el perfil.')),
      );
      return;
    }
    setState(() => _saving = true);
    await StorageService.instance.insertProfile(
      Profile(
        name: name,
        relation: _relation.text.trim().isEmpty ? null : _relation.text.trim(),
        colorValue: _color,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final String initial =
        _name.text.trim().isEmpty ? '?' : _name.text.trim()[0].toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Color(_color),
              child: Text(
                initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              hintText: 'Ej: Jorge',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _relation,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Etiqueta o parentesco (opcional)',
              hintText: 'Ej: Yo, Hijo, Madre...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Color del avatar',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              for (final int c in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == c ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _color == c
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_saving ? 'Guardando...' : 'Guardar perfil'),
            ),
          ),
        ],
      ),
    );
  }
}
