// lib/features/entreprise/data/entreprise_api.dart

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entreprise_models.dart';

class EntrepriseApi {
  final Dio _dio = DioClient.instance.dio;

  // ------------------ Helpers ------------------
  Map<String, dynamic> _clean(Map<String, dynamic> m) {
    final copy = Map<String, dynamic>.from(m);
    copy.removeWhere((_, v) => v == null || (v is String && v.trim().isEmpty));
    return copy;
  }

  /// Build a safe payload for create/update.
  /// - Cast `prix_unitaire` to **int** (DRF often uses IntegerField)
  /// - Drop null/empty values
  Map<String, dynamic> _payloadForUpsert(Equipment e) {
    return _clean({
      'categorie': e.categorie.value,
      'reference': e.reference,
      'marque': e.marque,
      'modele': e.modele,
      'nom_commercial': e.nomCommercial,
      // ⬇️ KEY FIX: integer for Django
      'prix_unitaire': e.prixUnitaire.isFinite ? e.prixUnitaire.round() : 0,
      'devise': e.devise,

      // Optional specs (send only when not null)
      'puissance_W': e.puissanceW,
      'capacite_Ah': e.capaciteAh,
      'tension_nominale_V': e.tensionNominaleV,
      'vmp_V': e.vmpV,
      'voc_V': e.vocV,
      'type_regulateur': e.typeRegulateur,
      'courant_A': e.courantA,
      'pv_voc_max_V': e.pvVocMaxV,
      'mppt_v_min_V': e.mpptVMinV,
      'mppt_v_max_V': e.mpptVMaxV,
      'puissance_surgeb_W': e.puissanceSurgebW,
      'entree_dc_V': e.entreeDcV,
      'section_mm2': e.sectionMm2,
      'ampacite_A': e.ampaciteA,

      'disponible': e.disponible,
      // Ne PAS envoyer des champs read-only (created_at, created_by_email, approuve_dimensionnement)
    });
  }

  Never _rethrowWithBody(DioException e, String ctx) {
    final body = e.response?.data;
    throw Exception('$ctx: ${e.message} '
        '${body is Map || body is List ? body : (body?.toString() ?? "")}');
  }

  // ------------------ Profil ------------------
  Future<UserProfile> getMyProfile() async {
    try {
      final res = await _dio.get(
        '/users/me/',
        options: Options(extra: {'requiresAuth': true}),
      );
      return UserProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur getMyProfile');
    }
  }

  Future<UserProfile> getUserProfile(int userId) async {
    try {
      final res = await _dio.get(
        '/users/$userId/',
        options: Options(extra: {'requiresAuth': true}),
      );
      return UserProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur getUserProfile');
    }
  }

  Future<UserProfile> updateUserProfile(int userId, UserProfile profile) async {
    try {
      final res = await _dio.patch(
        '/users/$userId/',
        data: profile.toJson(),
        options: Options(extra: {'requiresAuth': true}),
      );
      return UserProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur updateUserProfile');
    }
  }

  Future<void> changePassword(int userId, PasswordChangeRequest request) async {
    try {
      await _dio.post(
        '/users/$userId/change-password/',
        data: request.toJson(),
        options: Options(extra: {'requiresAuth': true}),
      );
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur changePassword');
    }
  }

  // ------------------ Équipements ------------------
  Future<List<Equipment>> getEquipments() async {
    try {
      final res = await _dio.get(
        '/equipements/',
        options: Options(extra: {'requiresAuth': true}),
      );
      return (res.data as List)
          .map((e) => Equipment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur getEquipments');
    }
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    try {
      final payload = _payloadForUpsert(equipment);
      final res = await _dio.post(
        '/equipements/',
        data: payload,
        options: Options(extra: {'requiresAuth': true}),
      );
      return Equipment.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur createEquipment');
    }
  }

  Future<Equipment> updateEquipment(Equipment equipment) async {
    try {
      final payload = _payloadForUpsert(equipment);
      final res = await _dio.patch(
        '/equipements/${equipment.id}/',
        data: payload,
        options: Options(extra: {'requiresAuth': true}),
      );
      return Equipment.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur updateEquipment');
    }
  }

  Future<void> deleteEquipment(int equipmentId) async {
    try {
      await _dio.delete(
        '/equipements/$equipmentId/',
        options: Options(extra: {'requiresAuth': true}),
      );
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur deleteEquipment');
    }
  }

  Future<Equipment> toggleEquipmentAvailability(
    int equipmentId,
    bool disponible,
  ) async {
    try {
      final res = await _dio.patch(
        '/equipements/$equipmentId/',
        data: {'disponible': disponible},
        options: Options(extra: {'requiresAuth': true}),
      );
      return Equipment.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      _rethrowWithBody(e, 'Erreur toggleEquipmentAvailability');
    }
  }
}
