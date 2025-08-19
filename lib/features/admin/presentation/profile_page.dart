// lib/features/admin/presentation/profile_page.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/providers.dart';

class AdminProfilePage extends ConsumerStatefulWidget {
  const AdminProfilePage({super.key});
  @override
  ConsumerState<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends ConsumerState<AdminProfilePage> {
  final _svc = _ProfileService();

  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  // Password form
  bool _showPwd = false;
  bool _changingPwd = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  final _oldPwd = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmPwd = TextEditingController();

  // Profile
  _AdminProfile? _profile;
  final _username = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _oldPwd.dispose();
    _newPwd.dispose();
    _confirmPwd.dispose();
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final id = await _svc.currentUserId();
      if (id == null) {
        if (!mounted) return;
        _showSnack('Session invalide. Veuillez vous reconnecter.');
        context.go('/admin-login');
        return;
      }
      final p = await _svc.fetchProfile(id);
      setState(() {
        _profile = p;
        _username.text = p.username ?? '';
        _email.text = p.email ?? '';
      });
    } on DioException catch (e) {
      _showSnack(_svc.prettyError(e));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_profile == null) return;
    setState(() => _saving = true);
    try {
      await _svc.patchProfile(
        _profile!.id,
        username: _username.text.trim(),
        email: _email.text.trim(),
      );
      // re-fetch pour être sûr
      final p = await _svc.fetchProfile(_profile!.id);
      setState(() {
        _profile = p;
        _editing = false;
      });
      _showSnack('Profil mis à jour avec succès', success: true);
    } on DioException catch (e) {
      _showSnack(_svc.prettyError(e));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_profile == null) return;
    final old = _oldPwd.text;
    final neu = _newPwd.text;
    final conf = _confirmPwd.text;
    if (old.isEmpty || neu.isEmpty || conf.isEmpty) {
      _showSnack('Tous les champs sont requis');
      return;
    }
    if (neu != conf) {
      _showSnack('Les nouveaux mots de passe ne correspondent pas');
      return;
    }
    setState(() => _changingPwd = true);
    try {
      await _svc.changePassword(_profile!.id, old, neu, conf);
      _showSnack('Mot de passe mis à jour', success: true);
      setState(() {
        _showPwd = false;
        _oldPwd.clear();
        _newPwd.clear();
        _confirmPwd.clear();
        _showOld = _showNew = _showConfirm = false;
      });
    } on DioException catch (e) {
      // Afficher champs/erreurs détaillées si la réponse est un dict
      final msg = _svc.fieldedOrGeneric(e);
      _showSnack(msg);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _changingPwd = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _username.text = _profile?.username ?? '';
      _email.text = _profile?.email ?? '';
    });
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : null,
      ),
    );
  }

  // Helpers role/status (pour chips)
  String _roleFromFlags(_AdminProfile p) {
    if (p.isSuperuser) return 'admin';
    if (p.isStaff) return 'manager';
    return (p.role?.toLowerCase() ?? 'user');
  }

  Color _roleBg(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFFFE4E6); // red-100
      case 'manager':
        return const Color(0xFFF3E8FF); // purple-100
      case 'user':
        return const Color(0xFFDBEAFE); // blue-100
      default:
        return const Color(0xFFF1F5F9); // slate-100
    }
  }

  Color _roleFg(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFB91C1C);
      case 'manager':
        return const Color(0xFF6D28D9);
      case 'user':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFF334155);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF16A34A);
      case 'inactive':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    // empêche l’accès si on n’est plus admin
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    if (!isAdmin) {
      // redirection douce
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/admin-login');
      });
    }

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Mon profil'),
      body: _loading
          ? const _CenteredLoader(label: 'Chargement du profil…')
          : (_profile == null
              ? _ErrorCard(
                  title: 'Erreur de chargement',
                  message:
                      'Impossible de charger le profil. Réessayez plus tard.',
                )
              : _buildContent()),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    final role = _roleFromFlags(p);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar placeholder
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.username?.isNotEmpty == true ? p.username! : '(sans nom)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(
                          role,
                          style: TextStyle(
                            color: _roleFg(role),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        avatar: Icon(Icons.shield_outlined,
                            size: 18, color: _roleFg(role)),
                        backgroundColor: _roleBg(role),
                        side: BorderSide(color: _roleBg(role)),
                      ),
                      Text(
                        '• ${p.status}',
                        style: TextStyle(
                          color: _statusColor(p.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_editing) ...[
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Sauvegarde…' : 'Sauvegarder'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _cancelEdit,
                icon: const Icon(Icons.close),
                label: const Text('Annuler'),
              ),
            ] else
              FilledButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Card infos
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (context, c) {
              final isWide = c.maxWidth >= 700;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildIdentityForm()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildAccountInfo(p)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildIdentityForm(),
                        const SizedBox(height: 16),
                        _buildAccountInfo(p),
                      ],
                    );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Card sécurité / mot de passe
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF16A34A)],
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Text(
                  'Sécurité du compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _showPwd ? _buildPwdForm() : _buildPwdCta(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(icon: Icons.alternate_email, label: 'Nom utilisateur'),
        const SizedBox(height: 6),
        _editing
            ? TextField(
                controller: _username,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'ex: admin',
                ),
              )
            : _ReadBox(text: _profile?.username ?? ''),
        const SizedBox(height: 14),
        const _FieldLabel(icon: Icons.mail_outline, label: 'Adresse email'),
        const SizedBox(height: 6),
        _editing
            ? TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'votre@email.com',
                ),
              )
            : _ReadBox(text: _profile?.email ?? ''),
      ],
    );
  }

  Widget _buildAccountInfo(_AdminProfile p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const _FieldLabel(icon: Icons.info_outline, label: 'Informations du compte'),
          const SizedBox(height: 8),
          _IconRow(
            icon: Icons.calendar_today_outlined,
            title: 'Membre depuis',
            value: _fmtDate(p.dateJoined),
          ),
          if (p.lastLogin != null)
            _IconRow(
              icon: Icons.verified_user_outlined,
              title: 'Dernière connexion',
              value: _fmtDateTime(p.lastLogin!),
            ),
        ],
      ),
    );
  }

  Widget _buildPwdCta() {
    return Column(
      children: [
        const Icon(Icons.lock_outline, size: 52, color: Colors.black26),
        const SizedBox(height: 8),
        const Text(
          'Modifier votre mot de passe',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Assurez-vous que votre compte reste sécurisé',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => setState(() => _showPwd = true),
          icon: const Icon(Icons.lock_reset),
          label: const Text('Modifier le mot de passe'),
        ),
      ],
    );
  }

  Widget _buildPwdForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PwdField(
          label: 'Mot de passe actuel',
          controller: _oldPwd,
          obscure: !_showOld,
          toggle: () => setState(() => _showOld = !_showOld),
        ),
        const SizedBox(height: 10),
        _PwdField(
          label: 'Nouveau mot de passe',
          controller: _newPwd,
          obscure: !_showNew,
          toggle: () => setState(() => _showNew = !_showNew),
        ),
        const SizedBox(height: 10),
        _PwdField(
          label: 'Confirmer le nouveau mot de passe',
          controller: _confirmPwd,
          obscure: !_showConfirm,
          toggle: () => setState(() => _showConfirm = !_showConfirm),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _changingPwd ? null : _changePassword,
              icon: _changingPwd
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_changingPwd ? 'Modification…' : 'Modifier le mot de passe'),
            ),
            OutlinedButton(
              onPressed: _changingPwd
                  ? null
                  : () {
                      setState(() {
                        _showPwd = false;
                        _oldPwd.clear();
                        _newPwd.clear();
                        _confirmPwd.clear();
                        _showOld = _showNew = _showConfirm = false;
                      });
                    },
              child: const Text('Annuler'),
            ),
          ],
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/* ------------------------------ Service/API ------------------------------ */

class _ProfileService {
  final Dio _dio = DioClient.instance.dio;

  Future<int?> currentUserId() async {
    // Essaye le JWT
    final token = await SecureAuthStorage.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final payload =
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final map = json.decode(payload) as Map<String, dynamic>;
          final id = map['user_id'] ?? map['id'] ?? map['sub'];
          if (id is int) return id;
          if (id is String) {
            final n = int.tryParse(id);
            if (n != null) return n;
          }
        }
      } catch (_) {}
    }

    // Fallback: /users/me/
    try {
      final res = await _dio.get(
        '/users/me/',
        options: Options(extra: {'requiresAuth': true}),
      );
      final data = res.data as Map<String, dynamic>;
      final id = data['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
    } catch (_) {}
    return null;
  }

  Future<_AdminProfile> fetchProfile(int id) async {
    final res = await _dio.get(
      '/users/$id/',
      options: Options(extra: {'requiresAuth': true}),
    );
    final m = Map<String, dynamic>.from(res.data as Map);
    return _AdminProfile.fromJson(m);
  }

  Future<void> patchProfile(int id, {required String username, required String email}) async {
    await _dio.patch(
      '/users/$id/',
      data: {'username': username, 'email': email},
      options: Options(extra: {'requiresAuth': true}),
    );
  }

  Future<void> changePassword(int id, String oldPwd, String newPwd, String confirmPwd) async {
    await _dio.post(
      '/users/$id/change-password/',
      data: {
        'old_password': oldPwd,
        'new_password': newPwd,
        'confirm_password': confirmPwd,
      },
      options: Options(extra: {'requiresAuth': true}),
    );
  }

  String prettyError(DioException e) {
    final code = e.response?.statusCode;
    if (e.response?.data is Map) {
      final m = e.response!.data as Map;
      if (m['detail'] != null) return '${m['detail']}';
    }
    return 'Erreur${code != null ? ' $code' : ''}: ${e.message ?? 'réseau'}';
  }

  String fieldedOrGeneric(DioException e) {
    try {
      if (e.response?.data is Map) {
        final m = Map<String, dynamic>.from(e.response!.data as Map);
        final buf = StringBuffer();
        m.forEach((k, v) {
          if (v is List) {
            for (final x in v) {
              buf.writeln('$k : $x');
            }
          } else {
            buf.writeln('$k : $v');
          }
        });
        final s = buf.toString().trim();
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}
    return prettyError(e);
  }
}

/* --------------------------------- Models -------------------------------- */

class _AdminProfile {
  final int id;
  final String? username;
  final String? email;
  final String role;
  final String status;
  final DateTime dateJoined;
  final DateTime? lastLogin;
  final bool isStaff;
  final bool isSuperuser;

  _AdminProfile({
    required this.id,
    this.username,
    this.email,
    required this.role,
    required this.status,
    required this.dateJoined,
    this.lastLogin,
    required this.isStaff,
    required this.isSuperuser,
  });

  factory _AdminProfile.fromJson(Map<String, dynamic> d) {
    // rôle déduit si absent
    final role = (d['role']?.toString().toLowerCase()) ??
        ((d['is_superuser'] == true)
            ? 'admin'
            : (d['is_staff'] == true)
                ? 'manager'
                : 'user');

    return _AdminProfile(
      id: _asInt(d['id']),
      username: d['username'] as String?,
      email: d['email'] as String?,
      role: role,
      status: (d['status']?.toString() ?? 'active'),
      dateJoined: _parseDate(d['date_joined']) ?? DateTime.now(),
      lastLogin: _parseDate(d['last_login']),
      isStaff: d['is_staff'] == true,
      isSuperuser: d['is_superuser'] == true,
    );
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is String) {
      try {
        return DateTime.parse(v).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/* --------------------------------- UI bits -------------------------------- */

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 10),
        Text(label),
      ]),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _ReadBox extends StatelessWidget {
  const _ReadBox({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PwdField extends StatelessWidget {
  const _PwdField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.toggle,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback toggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(icon: Icons.lock_outline, label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              tooltip: obscure ? 'Afficher' : 'Cacher',
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        color: const Color(0xFFFFF7ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.warning_amber_rounded,
                size: 42, color: Color(0xFFF97316)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF7C2D12))),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => context.go('/admin'),
              child: const Text('Retour au dashboard'),
            ),
          ]),
        ),
      ),
    );
  }
}
