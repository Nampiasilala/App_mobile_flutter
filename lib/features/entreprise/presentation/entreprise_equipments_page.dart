// lib/features/entreprise/presentation/entreprise_equipments_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entreprise_models.dart';
import '../providers.dart';

class EntrepriseEquipmentsPage extends ConsumerStatefulWidget {
  const EntrepriseEquipmentsPage({super.key});

  @override
  ConsumerState<EntrepriseEquipmentsPage> createState() => _EntrepriseEquipmentsPageState();
}

class _EntrepriseEquipmentsPageState extends ConsumerState<EntrepriseEquipmentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(equipmentsProvider.notifier).loadEquipments();
    });
  }

  void _showEquipmentDetails(Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => EquipmentDetailsDialog(equipment: equipment),
      barrierDismissible: true,
    );
  }

  void _showEquipmentModal([Equipment? equipment]) {
    showDialog(
      context: context,
      builder: (context) => EquipmentFormDialog(equipment: equipment),
      barrierDismissible: false,
    );
  }

  Future<void> _toggleAvailability(Equipment equipment) async {
    try {
      await ref.read(equipmentsProvider.notifier).toggleAvailability(
        equipment.id,
        !equipment.disponible,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              equipment.disponible 
                ? 'Équipement marqué comme indisponible' 
                : 'Équipement marqué comme disponible'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getCategoryColor(EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.panneauSolaire:
        return Colors.orange;
      case EquipmentCategory.batterie:
        return Colors.green;
      case EquipmentCategory.regulateur:
        return Colors.blue;
      case EquipmentCategory.onduleur:
        return Colors.purple;
      case EquipmentCategory.cable:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentsAsync = ref.watch(equipmentsProvider);
    final searchTerm = ref.watch(searchTermProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);
    final service = ref.watch(entrepriseServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec bouton retour
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Icon(Icons.precision_manufacturing, size: 28, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mes équipements',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton.icon(
                          onPressed: () => _showEquipmentModal(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Barre de recherche et filtres - Layout vertical pour mobile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Référence / Modèle / Catégorie...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ref.read(searchTermProvider.notifier).state = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EquipmentCategory?>(
                    value: categoryFilter,
                    decoration: InputDecoration(
                      labelText: 'Filtrer par catégorie',
                      prefixIcon: const Icon(Icons.filter_list),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<EquipmentCategory?>(
                        value: null,
                        child: Text('Toutes les catégories'),
                      ),
                      ...EquipmentCategory.values.map((category) =>
                        DropdownMenuItem<EquipmentCategory?>(
                          value: category,
                          child: Text(category.label),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(categoryFilterProvider.notifier).state = value;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Liste des équipements
            Expanded(
              child: equipmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(equipmentsProvider.notifier).loadEquipments(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (equipments) {
                  if (equipments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.precision_manufacturing, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun équipement',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Commencez par ajouter votre premier équipement',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showEquipmentModal(),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un équipement'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final displayEquipments = searchTerm.isEmpty && categoryFilter == null 
                      ? equipments 
                      : service.searchEquipments(equipments, searchTerm, categoryFilter);

                  if (displayEquipments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun résultat',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Essayez de modifier vos critères de recherche',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayEquipments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final equipment = displayEquipments[index];
                      return Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _showEquipmentDetails(equipment), // Changé ici : vue détails en lecture seule
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getCategoryColor(equipment.categorie).withOpacity(0.2),
                                      child: Icon(
                                        Icons.precision_manufacturing,
                                        color: _getCategoryColor(equipment.categorie),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            equipment.reference,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            equipment.displayName,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _showEquipmentModal(equipment);
                                            break;
                                          case 'delete':
                                            _showDeleteConfirmation(equipment);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 16),
                                              SizedBox(width: 8),
                                              Text('Modifier'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 16, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(equipment.categorie).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getCategoryColor(equipment.categorie).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            equipment.categorie.label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _getCategoryColor(equipment.categorie),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          service.formatPrice(equipment.prixUnitaire),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (equipment.marque != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.business, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            equipment.marque!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 8),
                                    
                                    Row(
                                      children: [
                                        const Text(
                                          'Statut: ',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        GestureDetector(
                                          onTap: () => _toggleAvailability(equipment),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: equipment.disponible 
                                                  ? Colors.green.withOpacity(0.1) 
                                                  : Colors.red.withOpacity(0.1),
                                              border: Border.all(
                                                color: equipment.disponible ? Colors.green : Colors.red,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  equipment.disponible ? Icons.check_circle : Icons.cancel,
                                                  size: 12,
                                                  color: equipment.disponible ? Colors.green : Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  equipment.disponible ? 'Disponible' : 'Indisponible',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: equipment.disponible ? Colors.green : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'équipement'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${equipment.reference}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(equipmentsProvider.notifier).deleteEquipment(equipment.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Équipement supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Dialog pour afficher les détails d'un équipement (lecture seule)
class EquipmentDetailsDialog extends ConsumerWidget {
  final Equipment equipment;

  const EquipmentDetailsDialog({super.key, required this.equipment});

  Color _getCategoryColor(EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.panneauSolaire:
        return Colors.orange;
      case EquipmentCategory.batterie:
        return Colors.green;
      case EquipmentCategory.regulateur:
        return Colors.blue;
      case EquipmentCategory.onduleur:
        return Colors.purple;
      case EquipmentCategory.cable:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(entrepriseServiceProvider);
    
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Détails de l\'équipement'),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => EquipmentFormDialog(equipment: equipment),
                  barrierDismissible: false,
                );
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec icône et référence
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _getCategoryColor(equipment.categorie).withOpacity(0.2),
                        child: Icon(
                          Icons.precision_manufacturing,
                          color: _getCategoryColor(equipment.categorie),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment.reference,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              equipment.displayName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: equipment.disponible 
                                    ? Colors.green.withOpacity(0.1) 
                                    : Colors.red.withOpacity(0.1),
                                border: Border.all(
                                  color: equipment.disponible ? Colors.green : Colors.red,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    equipment.disponible ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: equipment.disponible ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    equipment.disponible ? 'Disponible' : 'Indisponible',
                                    style: TextStyle(
                                      color: equipment.disponible ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Informations générales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations générales',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Catégorie', equipment.categorie.label, Icons.category, _getCategoryColor(equipment.categorie)),
                      if (equipment.marque != null) 
                        _buildDetailRow('Marque', equipment.marque!, Icons.business, Colors.grey[700]!),
                      if (equipment.modele != null) 
                        _buildDetailRow('Modèle', equipment.modele!, Icons.inventory, Colors.grey[700]!),
                      if (equipment.nomCommercial != null) 
                        _buildDetailRow('Nom commercial', equipment.nomCommercial!, Icons.label, Colors.grey[700]!),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Prix
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Prix unitaire', service.formatPrice(equipment.prixUnitaire), Icons.attach_money, Colors.green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Caractéristiques techniques
              if (equipment.puissanceW != null || equipment.capaciteAh != null || equipment.tensionNominaleV != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caractéristiques techniques',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (equipment.puissanceW != null) 
                          _buildDetailRow('Puissance', '${equipment.puissanceW} W', Icons.flash_on, Colors.orange),
                        if (equipment.capaciteAh != null) 
                          _buildDetailRow('Capacité', '${equipment.capaciteAh} Ah', Icons.battery_full, Colors.green),
                        if (equipment.tensionNominaleV != null) 
                          _buildDetailRow('Tension nominale', '${equipment.tensionNominaleV} V', Icons.electrical_services, Colors.blue),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => EquipmentFormDialog(equipment: equipment),
                          barrierDismissible: false,
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer l\'équipement'),
                            content: Text('Êtes-vous sûr de vouloir supprimer "${equipment.reference}" ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  try {
                                    await ref.read(equipmentsProvider.notifier).deleteEquipment(equipment.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Équipement supprimé avec succès'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erreur: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog pour ajouter/modifier un équipement
class EquipmentFormDialog extends ConsumerStatefulWidget {
  final Equipment? equipment;

  const EquipmentFormDialog({super.key, this.equipment});

  @override
  ConsumerState<EquipmentFormDialog> createState() => _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends ConsumerState<EquipmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _referenceController;
  late TextEditingController _marqueController;
  late TextEditingController _modeleController;
  late TextEditingController _nomCommercialController;
  late TextEditingController _prixController;
  late TextEditingController _puissanceController;
  late TextEditingController _capaciteController;
  late TextEditingController _tensionController;

  EquipmentCategory _selectedCategory = EquipmentCategory.autre;
  bool _disponible = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    final equipment = widget.equipment;
    _referenceController = TextEditingController(text: equipment?.reference ?? '');
    _marqueController = TextEditingController(text: equipment?.marque ?? '');
    _modeleController = TextEditingController(text: equipment?.modele ?? '');
    _nomCommercialController = TextEditingController(text: equipment?.nomCommercial ?? '');
    _prixController = TextEditingController(
      text: equipment?.prixUnitaire != null ? equipment!.prixUnitaire.toString() : ''
    );
    _puissanceController = TextEditingController(
      text: equipment?.puissanceW?.toString() ?? ''
    );
    _capaciteController = TextEditingController(
      text: equipment?.capaciteAh?.toString() ?? ''
    );
    _tensionController = TextEditingController(
      text: equipment?.tensionNominaleV?.toString() ?? ''
    );

    if (equipment != null) {
      _selectedCategory = equipment.categorie;
      _disponible = equipment.disponible;
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _nomCommercialController.dispose();
    _prixController.dispose();
    _puissanceController.dispose();
    _capaciteController.dispose();
    _tensionController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Convertir la catégorie au bon format pour l'API
      String categorieName;
      switch (_selectedCategory) {
        case EquipmentCategory.panneauSolaire:
          categorieName = 'panneau_solaire';
          break;
        case EquipmentCategory.batterie:
          categorieName = 'batterie';
          break;
        case EquipmentCategory.regulateur:
          categorieName = 'regulateur';
          break;
        case EquipmentCategory.onduleur:
          categorieName = 'onduleur';
          break;
        case EquipmentCategory.cable:
          categorieName = 'cable';
          break;
        default:
          categorieName = 'autre';
      }

      // Créer un objet Equipment temporaire pour les tests
      final equipment = Equipment(
        id: widget.equipment?.id ?? 0,
        categorie: _selectedCategory,
        reference: _referenceController.text.trim(),
        marque: _marqueController.text.trim().isEmpty ? null : _marqueController.text.trim(),
        modele: _modeleController.text.trim().isEmpty ? null : _modeleController.text.trim(),
        nomCommercial: _nomCommercialController.text.trim().isEmpty ? null : _nomCommercialController.text.trim(),
        prixUnitaire: double.parse(_prixController.text),
        puissanceW: _puissanceController.text.isEmpty ? null : double.tryParse(_puissanceController.text),
        capaciteAh: _capaciteController.text.isEmpty ? null : double.tryParse(_capaciteController.text),
        tensionNominaleV: _tensionController.text.isEmpty ? null : double.tryParse(_tensionController.text),
        disponible: _disponible,
      );

      print('Données à envoyer (catégorie convertie: $categorieName):'); // Debug
      print('Référence: ${equipment.reference}');
      print('Prix: ${equipment.prixUnitaire}');
      print('Disponible: ${equipment.disponible}');

      if (widget.equipment == null) {
        await ref.read(equipmentsProvider.notifier).addEquipment(equipment);
      } else {
        await ref.read(equipmentsProvider.notifier).updateEquipment(equipment);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.equipment == null 
                  ? 'Équipement ajouté avec succès' 
                  : 'Équipement modifié avec succès'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.equipment == null ? 'Ajouter un équipement' : 'Modifier l\'équipement',
            style: const TextStyle(fontSize: 18),
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveEquipment,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.equipment == null ? 'Ajouter' : 'Modifier',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations générales',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<EquipmentCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: EquipmentCategory.values.map((category) =>
                            DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ),
                          ).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Équipement disponible'),
                          subtitle: Text(_disponible ? 'Cet équipement est disponible' : 'Cet équipement n\'est pas disponible'),
                          value: _disponible,
                          onChanged: (value) => setState(() => _disponible = value),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Identification
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identification',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _referenceController,
                          decoration: const InputDecoration(
                            labelText: 'Référence *',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'La référence est obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _marqueController,
                          decoration: const InputDecoration(
                            labelText: 'Marque',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _modeleController,
                          decoration: const InputDecoration(
                            labelText: 'Modèle',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.inventory),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nomCommercialController,
                          decoration: const InputDecoration(
                            labelText: 'Nom commercial',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.label),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Prix
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prix',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _prixController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix unitaire (MGA) *',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Le prix est obligatoire';
                            }
                            final price = double.tryParse(value!);
                            if (price == null || price <= 0) {
                              return 'Prix invalide';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Caractéristiques techniques
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caractéristiques techniques (optionnel)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _puissanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Puissance (W)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.flash_on, color: Colors.orange),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _capaciteController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capacité (Ah)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.battery_full, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tensionController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tension nominale (V)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.electrical_services, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}