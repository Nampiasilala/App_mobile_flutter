// lib/features/admin/presentation/admin_dashboard_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  // Essaie d'extraire un email / identifiant depuis le payload du JWT access
  Future<String?> _loadAdminEmail() async {
    final token = await SecureAuthStorage.instance.getAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = json.decode(payload) as Map<String, dynamic>;

      // Clés possibles suivant backend
      final email = (map['email'] ??
              map['user_email'] ??
              map['sub'] ??
              map['username'] ??
              map['user']?['email'])
          ?.toString();
      return email;
    } catch (_) {
      return null;
    }
  }

  // Méthode pour gérer la déconnexion
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      // Afficher un dialog de confirmation
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Appeler la méthode de déconnexion du provider
        await ref.read(authStateProvider.notifier).logout();
        
        // Rediriger vers la page de connexion ou d'accueil
        if (context.mounted) {
          context.go('/'); // ou '/' selon votre routing
        }
      }
    } catch (e) {
      // Gérer l'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On garde le watch si tu t'en sers pour protéger la route via un guard
    final auth = ref.watch(authStateProvider);

    final items = <_AdminItem>[
      _AdminItem(
        route: '/admin/profile',
        title: 'Mon profil',
        desc: 'Voir et modifier mes informations',
        icon: Icons.person_outline,
        color: const Color(0xFF7C3AED),
      ),
      _AdminItem(
        route: '/admin/equipments',
        title: 'Équipements',
        desc: 'Gérer le catalogue d\'équipements',
        icon: Icons.build_outlined,
        color: const Color(0xFF2563EB),
      ),
      _AdminItem(
        route: '/admin/users',
        title: 'Utilisateurs',
        desc: 'Éditer, supprimer des comptes',
        icon: Icons.group_outlined,
        color: const Color(0xFF0EA5E9),
      ),
      _AdminItem(
        route: '/admin/parameters',
        title: 'Paramètres',
        desc: 'Configurer les paramètres du système',
        icon: Icons.settings_outlined,
        color: const Color(0xFF22C55E),
      ),
      _AdminItem(
        route: '/admin/history',
        title: 'Historique',
        desc: 'Voir l\'historique des calculs',
        icon: Icons.history,
        color: const Color(0xFFF59E0B),
      ),
      _AdminItem(
        route: '/admin/contents',
        title: 'Contenus',
        desc: 'Éditer les pages de contenu',
        icon: Icons.description_outlined,
        color: const Color(0xFF9333EA),
      ),
    ];

    // On construit toute la page dans un FutureBuilder pour alimenter le sous-titre de l'AppBar
    return FutureBuilder<String?>(
      future: _loadAdminEmail(),
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final email = snap.data;

        return Scaffold(
          appBar: buildSmartAppBar(
            context,
            'Admin',
            // ⬇️ Sous-titre directement dans l'AppBar
            subtitle: loading ? 'Connexion...' : (email ?? 'Connecté'),
            actions: [
              IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                tooltip: 'Accueil',
              ),
              // ⬇️ NOUVEAU : Bouton de déconnexion
              IconButton(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(Icons.logout),
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
              ),
            ),
            // ⚠️ Plus de header dans le body : on affiche directement la grille/list des cartes
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminCard(item: item),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* --------------------------------- Widgets -------------------------------- */

class _AdminItem {
  final String route;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _AdminItem({
    required this.route,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.item});
  final _AdminItem item;

  @override
  Widget build(BuildContext context) {
    return Card
    (
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go(item.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.desc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}