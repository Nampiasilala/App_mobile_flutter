import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../auth/providers.dart';
import '../data/users_service.dart';

enum RoleFilter { tous, admin, moderateur, utilisateur, invite }

extension RoleFilterLabel on RoleFilter {
  String get label => switch (this) {
        RoleFilter.tous => 'Tous',
        RoleFilter.admin => 'Administrateur',
        RoleFilter.moderateur => 'Modérateur',
        RoleFilter.utilisateur => 'Utilisateur',
        RoleFilter.invite => 'Invité',
      };
}

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});
  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _svc = AdminUsersService();

  bool _loading = true;
  bool _deleting = false;
  int? _deletingId;

  List<AdminUser> _all = [];
  String _search = '';
  RoleFilter _filter = RoleFilter.tous;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _svc.fetchUsers();
      setState(() => _all = users);
    } catch (e) {
      _snack('Échec du chargement des utilisateurs : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AdminUser> get _filtered {
    final t = _search.trim().toLowerCase();
    return _all.where((u) {
      final matchText = t.isEmpty ||
          u.username.toLowerCase().contains(t) ||
          u.email.toLowerCase().contains(t) ||
          u.role.toLowerCase().contains(t);
      final matchRole = switch (_filter) {
        RoleFilter.tous => true,
        RoleFilter.admin => u.role.toLowerCase() == 'admin' || u.role.toLowerCase() == 'administrateur',
        RoleFilter.moderateur => u.role.toLowerCase() == 'modérateur' || u.role.toLowerCase() == 'moderateur',
        RoleFilter.utilisateur => u.role.toLowerCase() == 'utilisateur' || u.role.toLowerCase() == 'user',
        RoleFilter.invite => u.role.toLowerCase() == 'invité' || u.role.toLowerCase() == 'invite',
      };
      return matchText && matchRole;
    }).toList();
  }

  Future<void> _confirmDelete(AdminUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l’utilisateur'),
        content: Text('Voulez-vous vraiment supprimer “${u.username}” ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) _delete(u.id);
  }

  Future<void> _delete(int id) async {
    setState(() {
      _deleting = true;
      _deletingId = id;
    });
    try {
      await _svc.deleteUser(id);
      setState(() {
        _all.removeWhere((e) => e.id == id);
      });
      _snack('Utilisateur supprimé avec succès', success: true);
    } catch (e) {
      _snack('Échec de la suppression : $e');
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
          _deletingId = null;
        });
      }
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? Colors.green.shade700 : null),
    );
    }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color _roleBg(String role) {
    final r = role.toLowerCase();
    if (r.contains('admin')) return const Color(0xFFFFE4E6);
    if (r.contains('mod')) return const Color(0xFFFEF9C3);
    if (r.contains('util') || r == 'user') return const Color(0xFFDCFCE7);
    return const Color(0xFFF1F5F9);
  }

  Color _roleFg(String role) {
    final r = role.toLowerCase();
    if (r.contains('admin')) return const Color(0xFFB91C1C);
    if (r.contains('mod')) return const Color(0xFF92400E);
    if (r.contains('util') || r == 'user') return const Color(0xFF166534);
    return const Color(0xFF334155);
  }

  @override
  Widget build(BuildContext context) {
    // garde d’accès : admin requis
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/admin-login');
      });
    }

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Gestion des utilisateurs'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Toolbar
            Row(
              children: [
                // Recherche
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, email ou rôle…',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                // Filtre rôle
                Expanded(
                  child: DropdownButtonFormField<RoleFilter>(
                    value: _filter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: RoleFilter.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _filter = v ?? RoleFilter.tous),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Rafraîchir',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table / liste
            Expanded(
              child: _loading
                  ? const _CenteredLoader(label: 'Chargement des utilisateurs…')
                  : _filtered.isEmpty
                      ? const _EmptyState()
                      : _UsersTable(
                          users: _filtered,
                          deletingId: _deletingId,
                          roleBg: _roleBg,
                          roleFg: _roleFg,
                          fmtDate: _fmtDate,
                          onDelete: _confirmDelete,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------- Widgets UI ------------------------------- */

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.deletingId,
    required this.roleBg,
    required this.roleFg,
    required this.fmtDate,
    required this.onDelete,
  });

  final List<AdminUser> users;
  final int? deletingId;
  final Color Function(String) roleBg;
  final Color Function(String) roleFg;
  final String Function(DateTime) fmtDate;
  final void Function(AdminUser) onDelete;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 680;

    if (!isWide) {
      // Cartes (mobile)
      return ListView.separated(
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final u = users[i];
          final isDel = deletingId == u.id;
          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    const Icon(Icons.mail_outline, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.username, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(u.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: isDel ? null : () => onDelete(u),
                      icon: isDel
                          ? const SizedBox.square(
                              dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(u.role,
                          style: TextStyle(color: roleFg(u.role), fontWeight: FontWeight.w600)),
                      backgroundColor: roleBg(u.role),
                      side: BorderSide(color: roleBg(u.role)),
                    ),
                    Chip(
                      label: Text('Inscription : ${fmtDate(u.joinDate)}'),
                      avatar: const Icon(Icons.calendar_today, size: 16),
                    ),
                  ],
                ),
              ]),
            ),
          );
        },
      );
    }

    // Table (desktop)
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Utilisateur')),
            DataColumn(label: Text('Rôle')),
            DataColumn(label: Text('Inscription')),
            DataColumn(label: Text('Actions'), numeric: true),
          ],
          rows: users.map((u) {
            final isDel = deletingId == u.id;
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  const Icon(Icons.mail_outline, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.username, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(u.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: roleBg(u.role),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: roleBg(u.role)),
                ),
                child: Text(u.role,
                    style: TextStyle(color: roleFg(u.role), fontWeight: FontWeight.w700, fontSize: 12)),
              )),
              DataCell(Text(u.joinDate.toLocal().toString().split(' ').first)),
              DataCell(Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Supprimer',
                    onPressed: isDel ? null : () => onDelete(u),
                    icon: isDel
                        ? const SizedBox.square(
                            dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 42, height: 42, child: CircularProgressIndicator()),
        const SizedBox(height: 10),
        Text(label),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.group_outlined, size: 48, color: Color(0xFFCBD5E1)),
        SizedBox(height: 8),
        Text('Aucun utilisateur ne correspond à votre recherche.'),
      ]),
    );
  }
}
