import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../auth/providers.dart';
import '../data/users_service.dart' show AdminUsersService, AdminUser, UserDetails;

/// Filtres alignés avec le frontend web
enum RoleFilter { tous, admin, entreprise }

extension RoleFilterLabel on RoleFilter {
  String get label => switch (this) {
        RoleFilter.tous => 'Tous',
        RoleFilter.admin => 'Admin',
        RoleFilter.entreprise => 'Entreprise',
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
  int? _deletingId;   // spinner suppression
  int? _togglingId;   // spinner toggle actif

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
      if (!mounted) return;
      setState(() => _all = users);
    } catch (e) {
      _snack('Échec du chargement des utilisateurs : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- Rôle “vue” (Admin/Entreprise) ---
  bool _isAdmin(String role) {
    final r = role.toLowerCase();
    return r.contains('admin') || r.contains('superuser') || r.contains('staff');
  }

  String _roleView(String rawRole) => _isAdmin(rawRole) ? 'Admin' : 'Entreprise';

  // --- Stats comme le web ---
  int get _totalCount => _all.length;
  int get _adminsCount => _all.where((u) => _isAdmin(u.role)).length;
  int get _entreprisesCount => _all.where((u) => !_isAdmin(u.role)).length;

  // --- Liste filtrée / recherchée ---
  List<AdminUser> get _filtered {
    final t = _search.trim().toLowerCase();
    return _all.where((u) {
      final matchText = t.isEmpty ||
          u.username.toLowerCase().contains(t) ||
          u.email.toLowerCase().contains(t) ||
          u.role.toLowerCase().contains(t);
      final matchRole = switch (_filter) {
        RoleFilter.tous => true,
        RoleFilter.admin => _isAdmin(u.role),
        RoleFilter.entreprise => !_isAdmin(u.role),
      };
      return matchText && matchRole;
    }).toList();
  }

  Future<void> _confirmDelete(AdminUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Voulez-vous vraiment supprimer « ${u.username} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    await _delete(u.id);
  }

  Future<void> _delete(int id) async {
    setState(() => _deletingId = id);
    try {
      await _svc.deleteUser(id);
      if (!mounted) return;
      setState(() => _all.removeWhere((e) => e.id == id));
      _snack('Utilisateur supprimé avec succès', success: true);
    } catch (e) {
      _snack('Échec de la suppression : $e');
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _toggleActive(AdminUser u, bool value) async {
    setState(() => _togglingId = u.id);
    try {
      final isActiveServer = await _svc.setActive(u.id, value);
      if (!mounted) return;
      setState(() {
        _all = _all.map((x) {
          if (x.id != u.id) return x;
          return AdminUser(
            id: x.id,
            username: x.username,
            email: x.email,
            role: x.role,
            joinDate: x.joinDate,
            isActive: isActiveServer,
          );
        }).toList();
      });
      _snack(isActiveServer ? 'Compte activé' : 'Compte désactivé', success: true);
    } catch (e) {
      _snack('Échec de la mise à jour du statut : $e');
    } finally {
      if (mounted) setState(() => _togglingId = null);
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : null,
      ),
    );
  }

  String _fmtDateLong(DateTime d) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color _roleBg(String roleView) {
    final r = roleView.toLowerCase();
    if (r.contains('admin')) return const Color(0xFFFFE4E6);
    if (r.contains('entreprise')) return const Color(0xFFDCFCE7);
    return const Color(0xFFF1F5F9);
  }

  Color _roleFg(String roleView) {
    final r = roleView.toLowerCase();
    if (r.contains('admin')) return const Color(0xFFB91C1C);
    if (r.contains('entreprise')) return const Color(0xFF166534);
    return const Color(0xFF334155);
  }

  void _openDetails(AdminUser u) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _UserDetailsSheet(
        userBase: u,
        roleViewOf: _roleView,
        roleBg: _roleBg,
        roleFg: _roleFg,
        fmtDateLong: _fmtDateLong,
        loadDetails: (id) => _svc.fetchUserDetails(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/admin-login');
      });
    }

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Gestion des utilisateurs'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Rechercher par nom ou email…',
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _search = v),
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 10),
              _FilterChipsRow(
                selected: _filter,
                totals: (_totalCount, _adminsCount, _entreprisesCount),
                onSelected: (f) => setState(() => _filter = f),
                onRefresh: _loading ? null : _load,
                refreshing: _loading,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const _CenteredLoader(label: 'Chargement des utilisateurs…')
                    : _filtered.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: _UsersList(
                              users: _filtered,
                              deletingId: _deletingId,
                              togglingId: _togglingId,
                              roleBg: _roleBg,
                              roleFg: _roleFg,
                              fmtDateLong: _fmtDateLong,
                              roleViewOf: _roleView,
                              onDelete: _confirmDelete,
                              onTapUser: _openDetails,
                              onToggleActive: _toggleActive,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------- Widgets UI ------------------------------- */

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selected,
    required this.totals,
    required this.onSelected,
    required this.onRefresh,
    required this.refreshing,
  });

  final RoleFilter selected;
  final (int total, int admins, int entreprises) totals;
  final ValueChanged<RoleFilter> onSelected;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final (total, admins, entreprises) = totals;

    Widget chip(RoleFilter f, String label, int count, {Color? color}) {
      final isSelected = f == selected;
      return ChoiceChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        labelStyle: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
        selectedColor: color?.withOpacity(0.18) ??
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
        onSelected: (_) => onSelected(f),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(RoleFilter.tous, 'Tous', total),
              chip(RoleFilter.admin, 'Admins', admins, color: Colors.red),
              chip(RoleFilter.entreprise, 'Entreprises', entreprises, color: Colors.green),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            tooltip: 'Rafraîchir',
            onPressed: onRefresh,
            icon: refreshing
                ? const SizedBox.square(
                    dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 20),
          ),
        ),
      ],
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.deletingId,
    required this.togglingId,
    required this.roleBg,
    required this.roleFg,
    required this.fmtDateLong,
    required this.roleViewOf,
    required this.onDelete,
    required this.onTapUser,
    required this.onToggleActive,
  });

  final List<AdminUser> users;
  final int? deletingId;
  final int? togglingId;
  final Color Function(String) roleBg;
  final Color Function(String) roleFg;
  final String Function(DateTime) fmtDateLong;
  final String Function(String rawRole) roleViewOf;
  final void Function(AdminUser) onDelete;
  final void Function(AdminUser) onTapUser;
  final void Function(AdminUser, bool) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = users[i];
        final isDel = deletingId == u.id;
        final isToggling = togglingId == u.id;
        final viewRole = roleViewOf(u.role);

        Color statusBg(bool active) => active ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);
        Color statusFg(bool active) => active ? const Color(0xFF166534) : const Color(0xFFB91C1C);

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTapUser(u),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                u.username,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                u.email,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),

                        // --- Switch Actif/Inactif ---
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Switch.adaptive(
                              value: u.isActive,
                              onChanged: (isDel || isToggling) ? null : (v) => onToggleActive(u, v),
                            ),
                            if (isToggling)
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),

                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: isDel ? null : () => onDelete(u),
                              child: Center(
                                child: isDel
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          viewRole,
                          style: TextStyle(color: roleFg(viewRole), fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: roleBg(viewRole),
                        side: BorderSide(color: roleBg(viewRole)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Chip(
                        label: Text(u.isActive ? 'Actif' : 'Inactif',
                            style: TextStyle(
                              color: statusFg(u.isActive),
                              fontWeight: FontWeight.w600,
                            )),
                        backgroundColor: statusBg(u.isActive),
                        side: BorderSide(color: statusBg(u.isActive)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        avatar: Icon(
                          u.isActive ? Icons.check_circle : Icons.block,
                          size: 16,
                          color: statusFg(u.isActive),
                        ),
                      ),
                      Chip(
                        label: Text('Inscription : ${fmtDateLong(u.joinDate)}'),
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* -------------------------- Bottom sheet des détails -------------------------- */

class _UserDetailsSheet extends StatelessWidget {
  const _UserDetailsSheet({
    required this.userBase,
    required this.roleViewOf,
    required this.roleBg,
    required this.roleFg,
    required this.fmtDateLong,
    required this.loadDetails,
  });

  final AdminUser userBase;
  final String Function(String rawRole) roleViewOf;
  final Color Function(String) roleBg;
  final Color Function(String) roleFg;
  final String Function(DateTime) fmtDateLong;

  /// Doit appeler /users/{id}/ et retourner les infos complètes
  final Future<UserDetails> Function(int id) loadDetails;

  @override
  Widget build(BuildContext context) {
    final viewRole = roleViewOf(userBase.role);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: FutureBuilder<UserDetails>(
        future: loadDetails(userBase.id),
        builder: (context, snap) {
          final header = Row(
            children: [
              const Icon(Icons.person, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Détails de l’utilisateur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          );

          if (snap.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 12),
                const _CenteredLoader(label: 'Chargement des détails…'),
              ],
            );
          }
          if (snap.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 12),
                _ErrorBox(message: 'Impossible de charger l’utilisateur : ${snap.error}'),
              ],
            );
          }
          final d = snap.data;
          if (d == null) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 12),
                const _ErrorBox(message: 'Aucune donnée.'),
              ],
            );
          }

          Color statusBg(bool active) => active ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);
          Color statusFg(bool active) => active ? const Color(0xFF166534) : const Color(0xFFB91C1C);

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(icon: Icons.badge_outlined, label: 'Nom d’utilisateur', value: d.username),
                      const SizedBox(height: 10),
                      _DetailRow(icon: Icons.mail_outline, label: 'Email', value: d.email),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Rôle',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text(
                              viewRole,
                              style: TextStyle(color: roleFg(viewRole), fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: roleBg(viewRole),
                            side: BorderSide(color: roleBg(viewRole)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        title: 'Inscription',
                        value: d.dateJoined != null ? _safeFmt(fmtDateLong, d.dateJoined) : '—',
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoTile(
                        title: 'Dernière connexion',
                        value: d.lastLogin != null ? _safeFmtDateTime(d.lastLogin!) : '—',
                        icon: Icons.schedule,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        (d.isActive ?? false) ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          color: statusFg(d.isActive ?? false),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: statusBg(d.isActive ?? false),
                      side: BorderSide(color: statusBg(d.isActive ?? false)),
                      avatar: Icon(
                        (d.isActive ?? false) ? Icons.check_circle : Icons.block,
                        size: 16,
                        color: statusFg(d.isActive ?? false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _InfoItem(label: 'Téléphone', value: d.phone ?? '—', icon: Icons.phone),
                          const SizedBox(height: 12),
                          _WebsiteItem(website: d.website),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionLabel(icon: Icons.location_on, text: 'Adresse'),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(d.address?.trim().isNotEmpty == true ? d.address! : '—'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel(icon: Icons.description_outlined, text: 'Description'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(d.description?.trim().isNotEmpty == true ? d.description! : '—'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  String _safeFmt(String Function(DateTime) fmt, DateTime? d) {
    if (d == null) return '—';
    return fmt(d);
  }

  String _safeFmtDateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }
}

/* ---------------------------------- UI bits --------------------------------- */

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(icon: icon, text: label),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _WebsiteItem extends StatelessWidget {
  const _WebsiteItem({this.website});
  final String? website;

  Uri? _parseUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final v = url.trim();
    final normalized = v.startsWith('http') ? v : 'https://$v';
    return Uri.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final uri = _parseUrl(website);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(icon: Icons.public, text: 'Site web'),
        const SizedBox(height: 6),
        if (uri == null)
          const Text('—', style: TextStyle(fontWeight: FontWeight.w600))
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  uri.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Ouvrir'),
                onPressed: () async {
                  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Impossible d’ouvrir le lien')),
                    );
                  }
                },
              ),
            ],
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      ],
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 42, height: 42, child: CircularProgressIndicator()),
          const SizedBox(height: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C))),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text('Aucun utilisateur ne correspond à votre recherche ou à vos filtres.'),
        ],
      ),
    );
  }
}
