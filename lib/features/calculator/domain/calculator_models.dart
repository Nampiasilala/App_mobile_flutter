// Inputs & résultats de calcul
class CalculationInput {
  final num E_jour;        // Wh/j
  final num P_max;         // W
  final num N_autonomie;   // jours
  final num H_solaire;     // kWh/m²/j
  final num V_batterie;    // 12 | 24 | 48
  final String localisation;

  CalculationInput({
    required this.E_jour,
    required this.P_max,
    required this.N_autonomie,
    required this.H_solaire,
    required this.V_batterie,
    required this.localisation,
  });

  Map<String, dynamic> toJson() => {
    'E_jour': E_jour,
    'P_max': P_max,
    'N_autonomie': N_autonomie,
    'H_solaire': H_solaire,
    'V_batterie': V_batterie,
    'localisation': localisation,
  };
}

class Equipment {
  final String modele;
  final String? reference;
  final num? puissance_W;
  final num? capacite_Ah;
  final num? tension_nominale_V;
  final num prix_unitaire;
  final String? devise;

  Equipment({
    required this.modele,
    this.reference,
    this.puissance_W,
    this.capacite_Ah,
    this.tension_nominale_V,
    required this.prix_unitaire,
    this.devise,
  });

  factory Equipment.fromJson(Map<String, dynamic> j) => Equipment(
    modele: j['modele'] ?? '',
    reference: j['reference'],
    puissance_W: j['puissance_W'],
    capacite_Ah: j['capacite_Ah'],
    tension_nominale_V: j['tension_nominale_V'],
    prix_unitaire: j['prix_unitaire'] ?? 0,
    devise: j['devise'],
  );
}

class EquipementsRecommandes {
  final Equipment? panneau;
  final Equipment? batterie;
  final Equipment? regulateur;
  final Equipment? onduleur;
  final Equipment? cable;

  EquipementsRecommandes({this.panneau, this.batterie, this.regulateur, this.onduleur, this.cable});

  factory EquipementsRecommandes.fromJson(Map<String, dynamic> j) => EquipementsRecommandes(
    panneau: j['panneau'] == null ? null : Equipment.fromJson(j['panneau']),
    batterie: j['batterie'] == null ? null : Equipment.fromJson(j['batterie']),
    regulateur: j['regulateur'] == null ? null : Equipment.fromJson(j['regulateur']),
    onduleur: j['onduleur'] == null ? null : Equipment.fromJson(j['onduleur']),
    cable: j['cable'] == null ? null : Equipment.fromJson(j['cable']),
  );
}

class CalculationResult {
  final num puissance_totale;
  final num capacite_batterie;
  final num bilan_energetique_annuel;
  final num cout_total;
  final int nombre_panneaux;
  final int nombre_batteries;
  final EquipementsRecommandes? equipements_recommandes;

  CalculationResult({
    required this.puissance_totale,
    required this.capacite_batterie,
    required this.bilan_energetique_annuel,
    required this.cout_total,
    required this.nombre_panneaux,
    required this.nombre_batteries,
    this.equipements_recommandes,
  });

  factory CalculationResult.fromJson(Map<String, dynamic> j) => CalculationResult(
    puissance_totale: j['puissance_totale'] ?? 0,
    capacite_batterie: j['capacite_batterie'] ?? 0,
    bilan_energetique_annuel: j['bilan_energetique_annuel'] ?? 0,
    cout_total: j['cout_total'] ?? 0,
    nombre_panneaux: (j['nombre_panneaux'] ?? 0).toInt(),
    nombre_batteries: (j['nombre_batteries'] ?? 0).toInt(),
    equipements_recommandes: j['equipements_recommandes'] == null
        ? null
        : EquipementsRecommandes.fromJson(j['equipements_recommandes']),
  );
}

// Aide DB (help-by-key)
class HelpItem {
  final String title;
  final String bodyHtml;
  HelpItem({required this.title, required this.bodyHtml});
}
