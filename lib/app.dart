// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/home/presentation/home_page.dart';
import 'features/calculator/presentation/calculate_page.dart';
import 'features/auth/presentation/login_page.dart';

import 'features/admin/presentation/admin_shell_page.dart';
import 'features/admin/presentation/admin_dashboard_page.dart';
import 'features/admin/presentation/contents_page.dart';
import 'features/admin/presentation/equipments_page.dart';
import 'features/admin/presentation/history_page.dart';
import 'features/admin/presentation/parameters_page.dart';
import 'features/admin/presentation/profile_page.dart';
import 'features/admin/presentation/users_page.dart';

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
  // ⚠️ IMPORTANT : ne PAS watcher ici, sinon le router est reconstruit
  final auth = ref.read(authStateProvider); // <-- read, pas watch

  final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Le router reste le même, mais se “réveille” quand auth change
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
        builder: (_, __, child) => AdminShellPage(child: child),
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
    ],

    // Redirections déterministes (jamais vers '/')
    redirect: (context, state) {
      final path = state.uri.path;
      final isAdmin = auth.isAdmin;
      final goingToLogin = path == '/admin-login';
      final goingToAdmin = path == '/admin' || path.startsWith('/admin/');

      if (goingToAdmin && !isAdmin) return '/admin-login';
      if (goingToLogin && isAdmin) return '/admin';
      return null;
    },

    errorBuilder: (_, __) => const _NotFoundPage(),
  );

  // Nettoyage propre si le provider est détruit
  ref.onDispose(router.dispose);
  return router;
});

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
            child: const Text('Retour à l’accueil'),
          ),
        ]),
      ),
    );
  }
}
