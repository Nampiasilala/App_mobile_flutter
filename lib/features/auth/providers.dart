import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = ChangeNotifierProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthState(repo);
});

class AuthState extends ChangeNotifier {
  final AuthRepository _repo;

  AuthState(this._repo);

  bool get isAdmin => _repo.isAdmin;
  bool get isEntreprise => _repo.isEntreprise;

  Stream<void> get authStateStream => _repo.changes;

  Future<bool> login(String id, String password) async {
    final ok = await _repo.login(id, password);
    notifyListeners();
    return ok;
  }

  Future<void> logout() async {
    await _repo.logout();
    notifyListeners();
  }
}