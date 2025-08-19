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

  // Essaie d’extraire un email / identifiant depuis le payload du JWT access
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider); // pour réagir si l’état change

    return Scaffold(
      appBar: buildSmartAppBar(
        context,
        'Tableau de bord administrateur',
        actions: [
          // Bouton "Accueil public"
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Accueil public'),
          ),
          const SizedBox(width: 8),
          // Badge "Admin"
          const _RoleChip(label: 'Admin'),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _loadAdminEmail(),
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          final email = snap.data;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tableau de bord administrateur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (loading)
                            const _ShimmerLine(width: 220)
                          else
                            Text(
                              email == null
                                  ? 'Connecté'
                                  : 'Connecté en tant que $email',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cartes
                LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final cols = w >= 1100
                        ? 4
                        : w >= 820
                            ? 3
                            : w >= 560
                                ? 2
                                : 1;

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
                        desc: 'Gérer le catalogue d’équipements',
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
                        desc: 'Voir l’historique des calculs',
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

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _AdminCard(item: items[i]),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
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
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go(item.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header ligne
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.desc,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontWeight: FontWeight.w600,
        ),
      ),
      avatar: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF6D28D9), size: 18),
      side: const BorderSide(color: Color(0xFFE9D5FF)),
      backgroundColor: const Color(0xFFF5F3FF),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({this.width = 140});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.06),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
