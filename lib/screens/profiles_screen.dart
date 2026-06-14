import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/storage_service.dart';
import 'add_profile_screen.dart';
import 'zones_screen.dart';

/// Pantalla principal (Home): cabecera con marca, lista de perfiles y menu.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfileEntry {
  _ProfileEntry(this.profile, this.count);
  final Profile profile;
  final int count;
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late Future<List<_ProfileEntry>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<List<_ProfileEntry>> _load() async {
    final List<Profile> profiles = await StorageService.instance.getProfiles();
    final List<_ProfileEntry> entries = <_ProfileEntry>[];
    for (final Profile p in profiles) {
      final int c = await StorageService.instance.countScansForProfile(p.id!);
      entries.add(_ProfileEntry(p, c));
    }
    return entries;
  }

  Future<void> _addProfile() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddProfileScreen()),
    );
    if (created == true) _refresh();
  }

  Future<void> _openProfile(Profile profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ZonesScreen(profile: profile)),
    );
    _refresh();
  }

  void _soon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature: proximamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const _Header(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Perfiles',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<_ProfileEntry>>(
              future: _future,
              builder: (BuildContext context,
                  AsyncSnapshot<List<_ProfileEntry>> snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final List<_ProfileEntry> entries =
                    snap.data ?? <_ProfileEntry>[];
                return Column(
                  children: <Widget>[
                    for (final _ProfileEntry e in entries)
                      _ProfileCard(
                        entry: e,
                        onTap: () => _openProfile(e.profile),
                      ),
                    _AddProfileCard(onTap: _addProfile),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Mas opciones',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: <Widget>[
                _MenuTile(
                  icon: Icons.backup_outlined,
                  title: 'Copia de seguridad',
                  subtitle: 'Guarda tus fotos a salvo',
                  onTap: () => _soon('Copia de seguridad'),
                ),
                _MenuTile(
                  icon: Icons.ios_share,
                  title: 'Enviar fotos',
                  subtitle: 'Comparte con tu especialista',
                  onTap: () => _soon('Enviar fotos'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF2E7D6B), Color(0xFF15584C)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.spa_outlined,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text(
                      'SkinDiary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Elige un perfil para empezar',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.entry, required this.onTap});

  final _ProfileEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Profile p = entry.profile;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Color(p.colorValue),
          child: Text(
            p.initial,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(p.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          <String>[
            if (p.relation != null && p.relation!.isNotEmpty) p.relation!,
            '${entry.count} foto(s)',
          ].join('  -  '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  const _AddProfileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_add_alt_1,
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(
                'Anadir perfil / usuario',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: const Text('Proximamente', style: TextStyle(fontSize: 11)),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        onTap: onTap,
      ),
    );
  }
}
