import 'package:flutter/material.dart';

class AdminShellPage extends StatelessWidget {
  final Widget child;
  const AdminShellPage({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Admin')), body: child);
  }
}
