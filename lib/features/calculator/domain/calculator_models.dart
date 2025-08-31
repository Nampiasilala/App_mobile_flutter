// Models robustes et alignés avec l'API

class CalculationInput {
  final num E_jour;
  final num P_max;
  final num N_autonomie;
  final double H_solaire;
  final num V_batterie;
  final String localisation;

  // ✅ champs demandés par le backend (comme sur le front web)
  final double H_vers_toit;

  /// "cout" ou "quantite"
  final String priorite_selection;

  CalculationInput({
    required this.E_jour,
    required this.P_max,
    required this.N_autonomie,
    required this.H_solaire,
    required this.V_batterie,
    required this.localisation,
    required this.H_vers_toit,
    required this.priorite_selection,
  });

  Map<String, dynamic> toJson() => {
    "E_jour": E_jour,
    "P_max": P_max,
    "N_autonomie": N_autonomie,
    "H_solaire": H_solaire,
    "V_batterie": V_batterie,
    "localisation": localisation,
    "H_vers_toit": H_vers_toit,
    "priorite_selection": priorite_selection,
  };
}

/* ======================= Résultat ======================= */

class CalculationResult {
  final num puissance_totale;
  final num capacite_batterie;
  final num bilan_energetique_annuel;
  final num cout_total;
  final int nombre_panneaux;
  final int nombre_batteries;

  // ✅ champs étendus (tous optionnels)
  final String? topologie_pv;
  final int? nb_pv_serie;
  final int? nb_pv_parallele;

  final String? topologie_batterie;
  final int? nb_batt_serie;
  final int? nb_batt_parallele;

  final double? longueur_cable_global_m;
  final num? prix_cable_global;
  final int? dimensionnement_id;

  final RecommendedEquipements? equipements_recommandes;

  CalculationResult({
    required this.puissance_totale,
    required this.capacite_batterie,
    required this.bilan_energetique_annuel,
    required this.cout_total,
    required this.nombre_panneaux,
    required this.nombre_batteries,
    this.topologie_pv,
    this.nb_pv_serie,
    this.nb_pv_parallele,
    this.topologie_batterie,
    this.nb_batt_serie,
    this.nb_batt_parallele,
    this.longueur_cable_global_m,
    this.prix_cable_global,
    this.dimensionnement_id,
    this.equipements_recommandes,
  });

  factory CalculationResult.fromJson(Map<String, dynamic> j) =>
      CalculationResult(
        puissance_totale: (j['puissance_totale'] ?? 0) as num,
        capacite_batterie: (j['capacite_batterie'] ?? 0) as num,
        bilan_energetique_annuel: (j['bilan_energetique_annuel'] ?? 0) as num,
        cout_total: (j['cout_total'] ?? 0) as num,
        nombre_panneaux: (j['nombre_panneaux'] ?? 0) as int,
        nombre_batteries: (j['nombre_batteries'] ?? 0) as int,
        topologie_pv: j['topologie_pv'] as String?,
        nb_pv_serie: j['nb_pv_serie'] as int?,
        nb_pv_parallele: j['nb_pv_parallele'] as int?,
        topologie_batterie: j['topologie_batterie'] as String?,
        nb_batt_serie: j['nb_batt_serie'] as int?,
        nb_batt_parallele: j['nb_batt_parallele'] as int?,
        longueur_cable_global_m: (j['longueur_cable_global_m'] is num)
            ? (j['longueur_cable_global_m'] as num).toDouble()
            : null,
        prix_cable_global: j['prix_cable_global'] as num?,
        dimensionnement_id: j['dimensionnement_id'] as int?,
        equipements_recommandes: j['equipements_recommandes'] == null
            ? null
            : RecommendedEquipements.fromJson(
                j['equipements_recommandes'] as Map<String, dynamic>,
              ),
      );
}

/* ============= Equipements ============= */

class RecommendedEquipements {
  final Equipment? panneau;
  final Equipment? batterie;
  final Equipment? regulateur;
  final Equipment? onduleur;
  final Equipment? cable;

  RecommendedEquipements({
    this.panneau,
    this.batterie,
    this.regulateur,
    this.onduleur,
    this.cable,
  });

  factory RecommendedEquipements.fromJson(Map<String, dynamic> j) =>
      RecommendedEquipements(
        panneau: j['panneau'] == null
            ? null
            : Equipment.fromJson(j['panneau'] as Map<String, dynamic>),
        batterie: j['batterie'] == null
            ? null
            : Equipment.fromJson(j['batterie'] as Map<String, dynamic>),
        regulateur: j['regulateur'] == null
            ? null
            : Equipment.fromJson(j['regulateur'] as Map<String, dynamic>),
        onduleur: j['onduleur'] == null
            ? null
            : Equipment.fromJson(j['onduleur'] as Map<String, dynamic>),
        cable: j['cable'] == null
            ? null
            : Equipment.fromJson(j['cable'] as Map<String, dynamic>),
      );
}

class Equipment {
  final int? id;
  final String? reference;
  final String? modele;
  final String? marque;
  final String? nom_commercial;

  // Caractéristiques éventuelles
  final num? puissance_W;
  final num? capacite_Ah;
  final num? tension_nominale_V;
  final num? courant_A; // régulateur
  final num? pv_voc_max_V; // régulateur
  final num? vmp_V; // panneau
  final num? voc_V; // panneau
  final num? imp_A; // panneau
  final String? section_mm2; // câble
  final num? ampacite_A; // câble

  // Prix
  final num prix_unitaire;
  final String? devise;

  Equipment({
    this.id,
    this.reference,
    this.modele,
    this.marque,
    this.nom_commercial,
    this.puissance_W,
    this.capacite_Ah,
    this.tension_nominale_V,
    this.courant_A,
    this.pv_voc_max_V,
    this.vmp_V,
    this.voc_V,
    this.imp_A,
    this.section_mm2,
    this.ampacite_A,
    required this.prix_unitaire,
    this.devise,
  });

  factory Equipment.fromJson(Map<String, dynamic> j) => Equipment(
    id: j['id'] as int?,
    reference: j['reference'] as String?,
    modele: j['modele'] as String?,
    marque: j['marque'] as String?,
    nom_commercial: j['nom_commercial'] as String?,
    puissance_W: j['puissance_W'] as num?,
    capacite_Ah: j['capacite_Ah'] as num?,
    tension_nominale_V: j['tension_nominale_V'] as num?,
    courant_A: j['courant_A'] as num?,
    pv_voc_max_V: j['pv_voc_max_V'] as num?,
    vmp_V: j['vmp_V'] as num?,
    voc_V: j['voc_V'] as num?,
    imp_A: j['imp_A'] as num?,
    section_mm2: (j['section_mm2'] ?? j['section_mm²'])?.toString(),
    ampacite_A: j['ampacite_A'] as num?,
    prix_unitaire: (j['prix_unitaire'] ?? 0) as num,
    devise: j['devise'] as String?,
  );
}

/* ============= Aide (pour helpMapProvider) ============= */

class HelpItem {
  final String title;
  final String bodyHtml;
  HelpItem({required this.title, required this.bodyHtml});
  // ✅ ajoute ceci
  factory HelpItem.fromJson(Map<String, dynamic> j) => HelpItem(
    title: (j['title'] ?? '').toString(),
    bodyHtml: (j['body_html'] ?? j['bodyHtml'] ?? j['body'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {'title': title, 'body_html': bodyHtml};
}
