// lib/core/ui/smart_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

PreferredSizeWidget buildSmartAppBar(
  BuildContext context,
  String title, {
  String? subtitle,            // <--- ajouté
  List<Widget>? actions,
}) {
  final router = GoRouter.of(context);
  final state = GoRouterState.of(context);        
  final currentPath = state.uri.path;             

  final notHome = currentPath != '/';
  final canPop = router.canPop() || (ModalRoute.of(context)?.canPop ?? false);
  final showBack = notHome || canPop;

  void onBack() {
    if (router.canPop()) {
      router.pop();
    } else {
      context.go('/'); 
    }
  }

  return AppBar(
    automaticallyImplyLeading: false,
    leading: showBack
        ? IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          )
        : null,
    title: subtitle == null
        ? Text(title)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
    actions: actions,
  );
}
