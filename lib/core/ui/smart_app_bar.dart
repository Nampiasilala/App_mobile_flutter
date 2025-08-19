// lib/core/ui/smart_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

PreferredSizeWidget buildSmartAppBar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
}) {
  final router = GoRouter.of(context);
  final state = GoRouterState.of(context);        // <-- source de vérité
  final currentPath = state.uri.path;             // '/', '/calculate', '/admin', etc.

  final notHome = currentPath != '/';
  final canPop = router.canPop() || (ModalRoute.of(context)?.canPop ?? false);
  final showBack = notHome || canPop;

  void onBack() {
    if (router.canPop()) {
      router.pop();
    } else {
      context.go('/'); // fallback vers l’accueil
    }
  }

  return AppBar(
    title: Text(title),
    automaticallyImplyLeading: false,
    leading: showBack
        ? IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          )
        : null,
    actions: actions,
  );
}
