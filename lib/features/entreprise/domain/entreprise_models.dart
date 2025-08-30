// lib/features/entreprise/domain/entreprise_models.dart

/// ---------- Helpers robustes de parsing ----------
double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    // garde uniquement chiffres, point et signe (retire " Ar", espaces, etc.)
    final cleaned = v.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
  return null;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) {
    final cleaned = v.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? fallback;
  }
  return fallback;
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (['true', '1', 'yes', 'y', 'oui'].contains(s)) return true;
    if (['false', '0', 'no', 'n', 'non'].contains(s)) return false;
  }
  return fallback;
}

/// ================== USER PROFILE ==================
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? dateJoined;
  final String? lastLogin;
  final String? phone;
  final String? address;
  final String? website;
  final String? description;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.dateJoined,
    this.lastLogin,
    this.phone,
    this.address,
    this.website,
    this.description,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _asInt(json['id']),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'entreprise',
      dateJoined: json['date_joined'] as String?,
      lastLogin: json['last_login'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'phone': phone ?? '',
      'address': address ?? '',
      'website': website ?? '',
      'description': description ?? '',
    };
  }

  UserProfile copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    String? dateJoined,
    String? lastLogin,
    String? phone,
    String? address,
    String? website,
    String? description,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      dateJoined: dateJoined ?? this.dateJoined,
      lastLogin: lastLogin ?? this.lastLogin,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      description: description ?? this.description,
    );
  }
}

/// ================== EQUIPMENT ==================
enum EquipmentCategory {
  panneauSolaire('panneau_solaire', 'Panneau solaire'),
  batterie('batterie', 'Batterie'),
  regulateur('regulateur', 'Régulateur'),
  onduleur('onduleur', 'Onduleur'),
  cable('cable', 'Câble'),
  disjoncteur('disjoncteur', 'Disjoncteur'),
  parafoudre('parafoudre', 'Parafoudre'),
  support('support', 'Support'),
  boitierJonction('boitier_jonction', 'Boîtier de jonction'),
  connecteur('connecteur', 'Connecteur'),
  monitoring('monitoring', 'Monitoring'),
  autre('autre', 'Autre');

  const EquipmentCategory(this.value, this.label);
  final String value;
  final String label;

  static EquipmentCategory fromString(String value) {
    return values.firstWhere(
      (c) => c.value == value,
      orElse: () => autre,
    );
  }
}

class Equipment {
  final int id;
  final EquipmentCategory categorie;
  final String reference;
  final String? marque;
  final String? modele;
  final String? nomCommercial;
  final double prixUnitaire;
  final String? devise;
  final double? puissanceW;
  final double? capaciteAh;
  final double? tensionNominaleV;
  final double? vmpV;
  final double? vocV;
  final String? typeRegulateur;
  final double? courantA;
  final double? pvVocMaxV;
  final double? mpptVMinV;
  final double? mpptVMaxV;
  final double? puissanceSurgebW;
  final String? entreeDcV;
  final double? sectionMm2;
  final double? ampaciteA;
  final bool disponible;
  final String? createdAt;
  final String? createdByEmail;

  const Equipment({
    required this.id,
    required this.categorie,
    required this.reference,
    required this.prixUnitaire,
    this.marque,
    this.modele,
    this.nomCommercial,
    this.devise,
    this.puissanceW,
    this.capaciteAh,
    this.tensionNominaleV,
    this.vmpV,
    this.vocV,
    this.typeRegulateur,
    this.courantA,
    this.pvVocMaxV,
    this.mpptVMinV,
    this.mpptVMaxV,
    this.puissanceSurgebW,
    this.entreeDcV,
    this.sectionMm2,
    this.ampaciteA,
    this.disponible = true,
    this.createdAt,
    this.createdByEmail,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: _asInt(json['id']),
      categorie: EquipmentCategory.fromString(
          (json['categorie'] as String?)?.toLowerCase() ?? 'autre'),
      reference: json['reference'] as String? ?? '',
      marque: json['marque'] as String?,
      modele: json['modele'] as String?,
      nomCommercial: json['nom_commercial'] as String?,
      // 👇 tolère "88 888 888 Ar", "777", 777, etc.
      prixUnitaire: _asDouble(json['prix_unitaire']) ?? 0.0,
      devise: json['devise'] as String?,
      puissanceW: _asDouble(json['puissance_W'] ?? json['puissance_w'] ?? json['puissance']),
      capaciteAh: _asDouble(json['capacite_Ah'] ?? json['capacite_ah'] ?? json['capacite']),
      tensionNominaleV: _asDouble(json['tension_nominale_V'] ?? json['tension_v']),
      vmpV: _asDouble(json['vmp_V'] ?? json['vmp_v']),
      vocV: _asDouble(json['voc_V'] ?? json['voc_v']),
      typeRegulateur: json['type_regulateur'] as String?,
      courantA: _asDouble(json['courant_A'] ?? json['courant']),
      pvVocMaxV: _asDouble(json['pv_voc_max_V'] ?? json['pv_voc_max_v']),
      mpptVMinV: _asDouble(json['mppt_v_min_V'] ?? json['mppt_v_min_v']),
      mpptVMaxV: _asDouble(json['mppt_v_max_V'] ?? json['mppt_v_max_v']),
      puissanceSurgebW: _asDouble(json['puissance_surgeb_W'] ?? json['puissance_surgeb_w']),
      entreeDcV: json['entree_dc_V'] as String? ?? json['entree_dc_v'] as String?,
      sectionMm2: _asDouble(json['section_mm2']),
      ampaciteA: _asDouble(json['ampacite_A'] ?? json['ampacite_a']),
      disponible: _asBool(json['disponible'], fallback: true),
      createdAt: json['created_at'] as String?,
      createdByEmail: json['created_by_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categorie': categorie.value,
      'reference': reference,
      'marque': marque,
      'modele': modele,
      'nom_commercial': nomCommercial,
      'prix_unitaire': prixUnitaire,
      'devise': devise,
      'puissance_W': puissanceW,
      'capacite_Ah': capaciteAh,
      'tension_nominale_V': tensionNominaleV,
      'vmp_V': vmpV,
      'voc_V': vocV,
      'type_regulateur': typeRegulateur,
      'courant_A': courantA,
      'pv_voc_max_V': pvVocMaxV,
      'mppt_v_min_V': mpptVMinV,
      'mppt_v_max_V': mpptVMaxV,
      'puissance_surgeb_W': puissanceSurgebW,
      'entree_dc_V': entreeDcV,
      'section_mm2': sectionMm2,
      'ampacite_A': ampaciteA,
      'disponible': disponible,
    };
  }

  Equipment copyWith({
    int? id,
    EquipmentCategory? categorie,
    String? reference,
    String? marque,
    String? modele,
    String? nomCommercial,
    double? prixUnitaire,
    String? devise,
    double? puissanceW,
    double? capaciteAh,
    double? tensionNominaleV,
    double? vmpV,
    double? vocV,
    String? typeRegulateur,
    double? courantA,
    double? pvVocMaxV,
    double? mpptVMinV,
    double? mpptVMaxV,
    double? puissanceSurgebW,
    String? entreeDcV,
    double? sectionMm2,
    double? ampaciteA,
    bool? disponible,
    String? createdAt,
    String? createdByEmail,
  }) {
    return Equipment(
      id: id ?? this.id,
      categorie: categorie ?? this.categorie,
      reference: reference ?? this.reference,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      nomCommercial: nomCommercial ?? this.nomCommercial,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      devise: devise ?? this.devise,
      puissanceW: puissanceW ?? this.puissanceW,
      capaciteAh: capaciteAh ?? this.capaciteAh,
      tensionNominaleV: tensionNominaleV ?? this.tensionNominaleV,
      vmpV: vmpV ?? this.vmpV,
      vocV: vocV ?? this.vocV,
      typeRegulateur: typeRegulateur ?? this.typeRegulateur,
      courantA: courantA ?? this.courantA,
      pvVocMaxV: pvVocMaxV ?? this.pvVocMaxV,
      mpptVMinV: mpptVMinV ?? this.mpptVMinV,
      mpptVMaxV: mpptVMaxV ?? this.mpptVMaxV,
      puissanceSurgebW: puissanceSurgebW ?? this.puissanceSurgebW,
      entreeDcV: entreeDcV ?? this.entreeDcV,
      sectionMm2: sectionMm2 ?? this.sectionMm2,
      ampaciteA: ampaciteA ?? this.ampaciteA,
      disponible: disponible ?? this.disponible,
      createdAt: createdAt ?? this.createdAt,
      createdByEmail: createdByEmail ?? this.createdByEmail,
    );
  }

  String get displayName {
    if (nomCommercial?.isNotEmpty == true) return nomCommercial!;
    if (modele?.isNotEmpty == true) return modele!;
    return reference;
  }
}

/// ================== PASSWORD DTO ==================
class PasswordChangeRequest {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const PasswordChangeRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    };
  }
}
