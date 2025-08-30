// lib/features/entreprise/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/entreprise_service.dart';
import 'domain/entreprise_models.dart';

// Service
final entrepriseServiceProvider = Provider<EntrepriseService>((ref) {
  return EntrepriseService();
});

// ---------- Profil ----------
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  UserProfileNotifier(this._service) : super(const AsyncValue.loading());
  final EntrepriseService _service;

  /// Charge le profil de l’utilisateur courant via /users/me/
  Future<void> loadMyProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.getMyProfile();
      state = AsyncValue.data(profile);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// (Optionnel) Charger un profil par ID si nécessaire
  Future<void> loadProfile(int userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.getUserProfile(userId);
      state = AsyncValue.data(profile);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateProfile(int userId, UserProfile profile) async {
    try {
      final updated = await _service.updateUserProfile(userId, profile);
      state = AsyncValue.data(updated);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> changePassword(int userId, PasswordChangeRequest request) async {
    await _service.changePassword(userId, request);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final service = ref.watch(entrepriseServiceProvider);
  return UserProfileNotifier(service);
});

// ---------- Équipements ----------
class EquipmentsNotifier extends StateNotifier<AsyncValue<List<Equipment>>> {
  EquipmentsNotifier(this._service) : super(const AsyncValue.loading());
  final EntrepriseService _service;

  Future<void> loadEquipments() async {
    state = const AsyncValue.loading();
    try {
      final equipments = await _service.getEquipments();
      state = AsyncValue.data(equipments);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addEquipment(Equipment equipment) async {
    try {
      final created = await _service.createEquipment(equipment);
      state = state.whenData((list) => [created, ...list]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    try {
      final updated = await _service.updateEquipment(equipment);
      state = state.whenData(
        (list) => list.map((e) => e.id == updated.id ? updated : e).toList(),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> deleteEquipment(int equipmentId) async {
    try {
      await _service.deleteEquipment(equipmentId);
      state = state.whenData(
        (list) => list.where((e) => e.id != equipmentId).toList(),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> toggleAvailability(int equipmentId, bool disponible) async {
    try {
      final updated =
          await _service.toggleEquipmentAvailability(equipmentId, disponible);
      state = state.whenData(
        (list) => list.map((e) => e.id == updated.id ? updated : e).toList(),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final equipmentsProvider =
    StateNotifierProvider<EquipmentsNotifier, AsyncValue<List<Equipment>>>(
        (ref) {
  final service = ref.watch(entrepriseServiceProvider);
  return EquipmentsNotifier(service);
});

// ---------- Recherche / filtres ----------
final searchTermProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<EquipmentCategory?>((ref) => null);

final filteredEquipmentsProvider = Provider<List<Equipment>>((ref) {
  final equipmentsAsync = ref.watch(equipmentsProvider);
  final term = ref.watch(searchTermProvider);
  final category = ref.watch(categoryFilterProvider);
  final service = ref.watch(entrepriseServiceProvider);

  return equipmentsAsync.maybeWhen(
    data: (list) => service.searchEquipments(list, term, category),
    orElse: () => <Equipment>[],
  );
});

// États UI
final isEditingProfileProvider = StateProvider<bool>((ref) => false);
final showPasswordFieldProvider = StateProvider<bool>((ref) => false);
