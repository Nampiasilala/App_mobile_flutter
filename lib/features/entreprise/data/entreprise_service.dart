// lib/features/entreprise/data/entreprise_service.dart

import '../domain/entreprise_models.dart';
import 'entreprise_api.dart';

class EntrepriseService {
  final EntrepriseApi _api = EntrepriseApi();

  // ===== PROFIL =====
  Future<UserProfile> getMyProfile() async {
    try {
      return await _api.getMyProfile();
    } catch (e) {
      throw Exception('Erreur lors du chargement de mon profil: $e');
    }
  }

  Future<UserProfile> getUserProfile(int userId) async {
    try {
      return await _api.getUserProfile(userId);
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil: $e');
    }
  }

  Future<UserProfile> updateUserProfile(int userId, UserProfile profile) async {
    try {
      return await _api.updateUserProfile(userId, profile);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  Future<void> changePassword(int userId, PasswordChangeRequest request) async {
    try {
      if (request.newPassword != request.confirmPassword) {
        throw Exception('Les nouveaux mots de passe ne correspondent pas');
      }
      if (request.newPassword.length < 6) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      }
      await _api.changePassword(userId, request);
    } catch (e) {
      throw Exception('Erreur lors du changement de mot de passe: $e');
    }
  }

  // ===== ÉQUIPEMENTS =====
  Future<List<Equipment>> getEquipments() async {
    try {
      return await _api.getEquipments();
    } catch (e) {
      throw Exception('Erreur lors du chargement des équipements: $e');
    }
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    try {
      _validateEquipment(equipment);
      return await _api.createEquipment(equipment);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'équipement: $e');
    }
  }

  Future<Equipment> updateEquipment(Equipment equipment) async {
    try {
      _validateEquipment(equipment);
      return await _api.updateEquipment(equipment);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'équipement: $e');
    }
  }

  Future<void> deleteEquipment(int equipmentId) async {
    try {
      await _api.deleteEquipment(equipmentId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'équipement: $e');
    }
  }

  Future<Equipment> toggleEquipmentAvailability(
      int equipmentId, bool disponible) async {
    try {
      return await _api.toggleEquipmentAvailability(equipmentId, disponible);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la disponibilité: $e');
    }
  }

  List<Equipment> searchEquipments(
    List<Equipment> equipments,
    String searchTerm,
    EquipmentCategory? filterCategory,
  ) {
    final term = searchTerm.toLowerCase().trim();

    return equipments.where((equipment) {
      final matchesSearch = term.isEmpty ||
          equipment.reference.toLowerCase().contains(term) ||
          (equipment.modele?.toLowerCase().contains(term) ?? false) ||
          (equipment.nomCommercial?.toLowerCase().contains(term) ?? false) ||
          (equipment.marque?.toLowerCase().contains(term) ?? false) ||
          equipment.categorie.label.toLowerCase().contains(term);

      final matchesCategory =
          filterCategory == null || equipment.categorie == filterCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _validateEquipment(Equipment equipment) {
    if (equipment.reference.trim().isEmpty) {
      throw Exception('La référence est obligatoire');
    }
    if (equipment.prixUnitaire <= 0) {
      throw Exception('Le prix doit être supérieur à 0');
    }
  }

  String formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]} ')} MGA';
  }
}
