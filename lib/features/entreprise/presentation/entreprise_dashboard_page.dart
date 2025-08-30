// lib/features/entreprise/presentation/entreprise_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../domain/entreprise_models.dart';

class EntrepriseDashboardPage extends ConsumerStatefulWidget {
  const EntrepriseDashboardPage({super.key});

  @override
  ConsumerState<EntrepriseDashboardPage> createState() =>
      _EntrepriseDashboardPageState();
}

class _EntrepriseDashboardPageState
    extends ConsumerState<EntrepriseDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Chargement initial: plus de userId, on utilise /users/me/
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(equipmentsProvider.notifier).loadEquipments();
      ref.read(userProfileProvider.notifier).loadMyProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final equipmentsAsync = ref.watch(equipmentsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(profileAsync: profileAsync),
              const SizedBox(height: 20),
              _TwoMainTiles(
                equipmentsAsync: equipmentsAsync,
                onEquipmentsTap: () => context.go('/entreprise/equipments'),
                onProfileTap: () => context.go('/entreprise/profile'),
              ),
              const SizedBox(height: 16),
              _SmallHint(),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Header ----------
class _Header extends StatelessWidget {
  const _Header({required this.profileAsync});
  final AsyncValue<UserProfile?> profileAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.business, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: profileAsync.when(
                data: (p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Entreprise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bienvenue, ${p?.username ?? 'Entreprise'}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                loading: () => const Text(
                  'Dashboard Entreprise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                error: (_, __) => const Text(
                  'Dashboard Entreprise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Deux tuiles principales (Équipements / Profil) - Layout vertical pour mobile ----------
class _TwoMainTiles extends StatelessWidget {
  const _TwoMainTiles({
    required this.equipmentsAsync,
    required this.onEquipmentsTap,
    required this.onProfileTap,
  });

  final AsyncValue<List<Equipment>> equipmentsAsync;
  final VoidCallback onEquipmentsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    int total = 0;
    int disponibles = 0;

    equipmentsAsync.when(
      data: (list) {
        total = list.length;
        disponibles = list.where((e) => e.disponible).length;
      },
      loading: () {},
      error: (_, __) {},
    );

    return Column(
      children: [
        _Tile(
          color: Colors.blue,
          icon: Icons.precision_manufacturing,
          title: 'Mes équipements',
          subtitle: equipmentsAsync.isLoading
              ? 'Chargement…'
              : '$total au total • $disponibles dispo',
          onTap: onEquipmentsTap,
        ),
        const SizedBox(height: 12),
        _Tile(
          color: Colors.purple,
          icon: Icons.account_circle,
          title: 'Mon profil',
          subtitle: 'Email, téléphone, adresse…',
          onTap: onProfileTap,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Astuce : retrouvez toutes vos infos en cliquant sur « Mes équipements » ou « Mon profil ».',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}