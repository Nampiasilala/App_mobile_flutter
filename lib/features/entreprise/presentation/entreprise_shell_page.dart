import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers.dart';

class EntrepriseShellPage extends ConsumerWidget {
  final String locationPath;
  final Widget child;

  const EntrepriseShellPage({
    super.key,
    required this.locationPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entreprise Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authStateProvider).logout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref),
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.business, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text('Entreprise', style: TextStyle(color: Colors.white, fontSize: 20)),
                Text('Dashboard', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerTile(
            context, 
            icon: Icons.dashboard, 
            title: 'Dashboard', 
            path: '/entreprise'
          ),
          _buildDrawerTile(
            context, 
            icon: Icons.precision_manufacturing, 
            title: 'Équipements', 
            path: '/entreprise/equipments'
          ),
          _buildDrawerTile(
            context, 
            icon: Icons.account_circle, 
            title: 'Profil', 
            path: '/entreprise/profile'
          ),
          const Divider(),
          _buildDrawerTile(
            context, 
            icon: Icons.home, 
            title: 'Page d\'accueil publique', 
            path: '/'
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.of(context).pop(); // Fermer le drawer
              await ref.read(authStateProvider).logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String path
  }) {
    final isSelected = locationPath == path || locationPath.startsWith('$path/');
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : null),
      title: Text(title),
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop();
        context.go(path);
      },
    );
  }
}