import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/home/presentation/home_page.dart';
import 'features/calculator/presentation/calculate_page.dart';
import 'features/auth/presentation/login_page.dart';

// Admin imports
import 'features/admin/presentation/admin_shell_page.dart';
import 'features/admin/presentation/admin_dashboard_page.dart';
import 'features/admin/presentation/contents_page.dart';
import 'features/admin/presentation/equipments_page.dart';
import 'features/admin/presentation/history_page.dart';
import 'features/admin/presentation/parameters_page.dart';
import 'features/admin/presentation/profile_page.dart';
import 'features/admin/presentation/users_page.dart';

// Entreprise imports
import 'features/entreprise/presentation/entreprise_shell_page.dart';
import 'features/entreprise/presentation/entreprise_dashboard_page.dart';
import 'features/entreprise/presentation/entreprise_equipments_page.dart';
import 'features/entreprise/presentation/entreprise_profile_page.dart';

import 'features/auth/providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'Calculateur Solaire',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authStateProvider);

  final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: auth,

    routes: [
      // Public
      GoRoute(
        path: '/',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/calculate',
        builder: (_, __) => const CalculatePage(),
      ),
      GoRoute(
        path: '/admin-login',
        builder: (_, __) => const LoginPage(),
      ),

      // Admin (Shell + enfants)
      ShellRoute(
        builder: (_, state, child) => AdminShellPage(
          locationPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminDashboardPage(),
            routes: [
              GoRoute(path: 'contents',    builder: (_, __) => const ContentsPage()),
              GoRoute(path: 'equipments',  builder: (_, __) => const AdminEquipmentsPage()),
              GoRoute(path: 'history',     builder: (_, __) => const AdminHistoryPage()),
              GoRoute(path: 'parameters',  builder: (_, __) => const ParametersPage()),
              GoRoute(path: 'profile',     builder: (_, __) => const AdminProfilePage()),
              GoRoute(path: 'users',       builder: (_, __) => const UsersPage()),
            ],
          ),
        ],
      ),

      // Entreprise (Shell + enfants) - AJOUTÉ
      ShellRoute(
        builder: (_, state, child) => EntrepriseShellPage(
          locationPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/entreprise',
            builder: (_, __) => const EntrepriseDashboardPage(),
            routes: [
              GoRoute(path: 'equipments', builder: (_, __) => const EntrepriseEquipmentsPage()),
              GoRoute(path: 'projects',   builder: (_, __) => const _EntrepriseProjectsPage()),
              GoRoute(path: 'users',      builder: (_, __) => const _EntrepriseUsersPage()),
              GoRoute(path: 'profile',    builder: (_, __) => const EntrepriseProfilePage()),
            ],
          ),
        ],
      ),
    ],

    // Redirections mises à jour pour entreprise
    redirect: (context, state) {
      final path = state.uri.path;
      final isAdmin = auth.isAdmin;
      final isEntreprise = auth.isEntreprise;
      final goingToLogin = path == '/admin-login';
      final goingToAdmin = path == '/admin' || path.startsWith('/admin/');
      final goingToEntreprise = path == '/entreprise' || path.startsWith('/entreprise/');

      // Protéger les routes admin
      if (goingToAdmin && !isAdmin) return '/admin-login';
      
      // Protéger les routes entreprise
      if (goingToEntreprise && !isEntreprise && !isAdmin) return '/admin-login';
      
      // Redirection après login
      if (goingToLogin && isAdmin) return '/admin';
      if (goingToLogin && isEntreprise && !isAdmin) return '/entreprise';
      
      return null;
    },

    errorBuilder: (_, __) => const _NotFoundPage(),
  );

  ref.onDispose(router.dispose);
  return router;
});

// Pages temporaires
class _EntrepriseProjectsPage extends StatelessWidget {
  const _EntrepriseProjectsPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Projets Entreprise', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Fonctionnalité en cours de développement'),
          ],
        ),
      ),
    );
  }
}

class _EntrepriseUsersPage extends StatelessWidget {
  const _EntrepriseUsersPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Utilisateurs Entreprise', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Fonctionnalité en cours de développement'),
          ],
        ),
      ),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Page introuvable'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Retour à l\'accueil'),
          ),
        ]),
      ),
    );
  }
}
