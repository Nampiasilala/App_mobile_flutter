enum Categorie {
  panneau_solaire,
  batterie,
  regulateur,
  onduleur,
  cable,
  disjoncteur,
  parafoudre,
  support,
  boitier_jonction,
  connecteur,
  monitoring,
  autre,
}

const Map<Categorie, String> kCategoryLabel = {
  Categorie.panneau_solaire: 'Panneau solaire',
  Categorie.batterie: 'Batterie',
  Categorie.regulateur: 'Régulateur',
  Categorie.onduleur: 'Onduleur',
  Categorie.cable: 'Câble',
  Categorie.disjoncteur: 'Disjoncteur',
  Categorie.parafoudre: 'Parafoudre',
  Categorie.support: 'Support',
  Categorie.boitier_jonction: 'Boîtier de jonction',
  Categorie.connecteur: 'Connecteur',
  Categorie.monitoring: 'Monitoring',
  Categorie.autre: 'Autre',
};

class Equipment {
  final int id;
  final Categorie categorie;
  final String reference;
  final String? marque;
  final String? modele;
  final String? nomCommercial;
  final num prixUnitaire;
  final String? devise;
  final num? puissanceW;
  final num? capaciteAh;
  final num? tensionNominaleV;
  final num? vmpV;
  final num? vocV;
  final String? typeRegulateur; // MPPT | PWM
  final num? courantA;
  final num? pvVocMaxV;
  final num? mpptVMinV;
  final num? mpptVMaxV;
  final num? puissanceSurgebW;
  final String? entreeDcV;
  final num? sectionMm2;
  final num? ampaciteA;

  Equipment({
    required this.id,
    required this.categorie,
    required this.reference,
    required this.prixUnitaire,
    this.devise,
    this.marque,
    this.modele,
    this.nomCommercial,
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
  });

  factory Equipment.fromJson(Map<String, dynamic> j) {
    Categorie parseCat(String? s) {
      switch (s) {
        case 'panneau_solaire': return Categorie.panneau_solaire;
        case 'batterie':        return Categorie.batterie;
        case 'regulateur':      return Categorie.regulateur;
        case 'onduleur':        return Categorie.onduleur;
        case 'cable':           return Categorie.cable;
        case 'disjoncteur':     return Categorie.disjoncteur;
        case 'parafoudre':      return Categorie.parafoudre;
        case 'support':         return Categorie.support;
        case 'boitier_jonction':return Categorie.boitier_jonction;
        case 'connecteur':      return Categorie.connecteur;
        case 'monitoring':      return Categorie.monitoring;
        default:                return Categorie.autre;
      }
    }

    num? toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    int toInt(dynamic v) => (v is int) ? v : int.tryParse('$v') ?? 0;

    return Equipment(
      id: toInt(j['id']),
      categorie: parseCat(j['categorie'] as String?),
      reference: (j['reference'] ?? '') as String,
      marque: j['marque'] as String?,
      modele: j['modele'] as String?,
      nomCommercial: j['nom_commercial'] as String?,
      prixUnitaire: toNum(j['prix_unitaire']) ?? 0,
      devise: j['devise'] as String?,
      puissanceW: toNum(j['puissance_W']),
      capaciteAh: toNum(j['capacite_Ah']),
      tensionNominaleV: toNum(j['tension_nominale_V']),
      vmpV: toNum(j['vmp_V']),
      vocV: toNum(j['voc_V']),
      typeRegulateur: j['type_regulateur'] as String?,
      courantA: toNum(j['courant_A']),
      pvVocMaxV: toNum(j['pv_voc_max_V']),
      mpptVMinV: toNum(j['mppt_v_min_V']),
      mpptVMaxV: toNum(j['mppt_v_max_V']),
      puissanceSurgebW: toNum(j['puissance_surgeb_W']),
      entreeDcV: j['entree_dc_V'] as String?,
      sectionMm2: toNum(j['section_mm2']),
      ampaciteA: toNum(j['ampacite_A']),
    );
  }

  Map<String, dynamic> toJson() {
    String catToWire(Categorie c) => c.toString().split('.').last;
    final m = <String, dynamic>{
      'categorie': catToWire(categorie),
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
    };
    m.removeWhere((k, v) => v == null || (v is String && v.isEmpty));
    return m;
  }
}
