import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShellPage extends StatelessWidget {
  final Widget child;
  final String locationPath; // reçu depuis ShellRoute (state.uri.path)
  
  const AdminShellPage({
    super.key,
    required this.child,
    required this.locationPath,
  });

  // Destinations (labels requis, masqués visuellement)
  static const _destinations = <_AdminDest>[
    _AdminDest('/admin', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _AdminDest('/admin/profile', Icons.person_outline, Icons.person, 'Profil'),
    _AdminDest('/admin/equipments', Icons.build_outlined, Icons.build, 'Équipements'),
    _AdminDest('/admin/users', Icons.group_outlined, Icons.group, 'Utilisateurs'),
    _AdminDest('/admin/parameters', Icons.settings_outlined, Icons.settings, 'Paramètres'),
    _AdminDest('/admin/history', Icons.history_outlined, Icons.history, 'Historique'),
    _AdminDest('/admin/contents', Icons.description_outlined, Icons.description, 'Contenus'),
  ];

  int _indexForLocation(String path) {
    // Nettoyage du path (enlever trailing slash)
    final cleanPath = path.endsWith('/') && path.length > 1 
        ? path.substring(0, path.length - 1) 
        : path;
    
    // Chercher correspondance exacte d'abord
    for (int i = 0; i < _destinations.length; i++) {
      if (cleanPath == _destinations[i].path) {
        return i;
      }
    }
    
    // Puis chercher correspondance par préfixe
    for (int i = 0; i < _destinations.length; i++) {
      if (cleanPath.startsWith('${_destinations[i].path}/')) {
        return i;
      }
    }
    
    return 0; // Dashboard par défaut
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentIndex = _indexForLocation(locationPath);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, // icônes seules
          indicatorColor: scheme.primaryContainer, // pastille actif
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: selected ? 28 : 24, // relief taille
              color: selected ? scheme.primary : scheme.onSurfaceVariant, // relief couleur
            );
          }),
          height: 64,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) {
            final dest = _destinations[i];
            if (locationPath != dest.path) context.go(dest.path);
          },
          destinations: _destinations.map((d) {
            return NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label, // masqué visuellement
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminDest {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label; // requis par NavigationDestination
  
  const _AdminDest(this.path, this.icon, this.selectedIcon, this.label);
}