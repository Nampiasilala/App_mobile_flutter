// lib/features/entreprise/presentation/entreprise_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers.dart';
import '../domain/entreprise_models.dart';
import '../providers.dart';

class EntrepriseProfilePage extends ConsumerStatefulWidget {
  const EntrepriseProfilePage({super.key});

  @override
  ConsumerState<EntrepriseProfilePage> createState() => _EntrepriseProfilePageState();
}

class _EntrepriseProfilePageState extends ConsumerState<EntrepriseProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Contrôleurs pour le formulaire de profil
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  // Contrôleurs pour le changement de mot de passe
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isPasswordLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _descriptionController = TextEditingController();

    // Charger le profil au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authStateProvider);
      if (auth.isEntreprise || auth.isAdmin) {
        // Simuler un userId - dans la vraie app, récupérer depuis l'auth
        ref.read(userProfileProvider.notifier).loadProfile(3); // Utilise l'ID depuis le JWT
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateControllers(UserProfile profile) {
    _usernameController.text = profile.username;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    _websiteController.text = profile.website ?? '';
    _descriptionController.text = profile.description ?? '';
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'entreprise':
        return Colors.green;
      case 'manager':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileAsync = ref.read(userProfileProvider);
      final currentProfile = profileAsync.value;
      if (currentProfile == null) return;

      final updatedProfile = currentProfile.copyWith(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      await ref.read(userProfileProvider.notifier).updateProfile(currentProfile.id, updatedProfile);
      ref.read(isEditingProfileProvider.notifier).state = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isPasswordLoading = true);

    try {
      final profileAsync = ref.read(userProfileProvider);
      final currentProfile = profileAsync.value;
      if (currentProfile == null) return;

      final passwordRequest = PasswordChangeRequest(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      await ref.read(userProfileProvider.notifier).changePassword(currentProfile.id, passwordRequest);

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ref.read(showPasswordFieldProvider.notifier).state = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe changé avec succès'),
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
      setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final isEditing = ref.watch(isEditingProfileProvider);
    final showPasswordField = ref.watch(showPasswordFieldProvider);

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(userProfileProvider.notifier).loadProfile(3),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profil non trouvé'));
            }

            // Mettre à jour les contrôleurs si pas en mode édition
            if (!isEditing) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateControllers(profile);
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec bouton retour
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Icon(Icons.business, size: 28, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profil entreprise',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Boutons d'action - Version mobile
                  if (isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveProfile,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isLoading ? 'Sauvegarde...' : 'Sauvegarder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref.read(isEditingProfileProvider.notifier).state = false;
                              _updateControllers(profile);
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Annuler'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => ref.read(isEditingProfileProvider.notifier).state = true,
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier le profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Carte d'identité
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Avatar et nom
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.green.shade100,
                                child: Text(
                                  profile.username.isNotEmpty ? profile.username[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isEditing)
                                      TextFormField(
                                        controller: _usernameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nom d\'entreprise',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        validator: (value) {
                                          if (value?.trim().isEmpty ?? true) {
                                            return 'Le nom est requis';
                                          }
                                          return null;
                                        },
                                      )
                                    else
                                      Text(
                                        profile.username,
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(profile.role).withOpacity(0.1),
                                        border: Border.all(color: _getRoleColor(profile.role).withOpacity(0.3)),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shield, size: 16, color: _getRoleColor(profile.role)),
                                          const SizedBox(width: 4),
                                          Text(
                                            profile.role,
                                            style: TextStyle(
                                              color: _getRoleColor(profile.role),
                                              fontSize: 12,
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
                          
                          const SizedBox(height: 20),
                          
                          // Informations dates en colonnes pour mobile
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Membre depuis', 
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(profile.dateJoined), 
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              ),
                              if (profile.lastLogin != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Dernière connexion', 
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(profile.lastLogin), 
                                        style: const TextStyle(fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Formulaire de profil
                  Form(
                    key: _formKey,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations de contact',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Email
                            _buildFormField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email,
                              isEditing: isEditing,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return 'L\'email est requis';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Téléphone
                            _buildFormField(
                              controller: _phoneController,
                              label: 'Téléphone',
                              icon: Icons.phone,
                              isEditing: isEditing,
                              keyboardType: TextInputType.phone,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Adresse
                            _buildFormField(
                              controller: _addressController,
                              label: 'Adresse',
                              icon: Icons.location_on,
                              isEditing: isEditing,
                              maxLines: 3,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Site web
                            _buildFormField(
                              controller: _websiteController,
                              label: 'Site web',
                              icon: Icons.language,
                              isEditing: isEditing,
                              keyboardType: TextInputType.url,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Description
                            _buildFormField(
                              controller: _descriptionController,
                              label: 'Description',
                              icon: Icons.description,
                              isEditing: isEditing,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sécurité du compte
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade600, Colors.blue.shade600],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Sécurité du compte',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (showPasswordField) ...[
                            Form(
                              key: _passwordFormKey,
                              child: Column(
                                children: [
                                  // Mot de passe actuel
                                  TextFormField(
                                    controller: _oldPasswordController,
                                    obscureText: _obscureOldPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Mot de passe actuel',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureOldPassword ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Mot de passe actuel requis';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Nouveau mot de passe
                                  TextFormField(
                                    controller: _newPasswordController,
                                    obscureText: _obscureNewPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Nouveau mot de passe',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Nouveau mot de passe requis';
                                      }
                                      if (value!.length < 6) {
                                        return 'Au moins 6 caractères';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Confirmation mot de passe
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Confirmer le mot de passe',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      prefixIcon: const Icon(Icons.check_circle, color: Colors.blue),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Confirmation requise';
                                      }
                                      if (value != _newPasswordController.text) {
                                        return 'Mots de passe différents';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Boutons d'action pour mot de passe - Version mobile
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isPasswordLoading ? null : _changePassword,
                                          icon: _isPasswordLoading
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.check_circle),
                                          label: Text(_isPasswordLoading ? 'Modification...' : 'Modifier le mot de passe'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: () {
                                            ref.read(showPasswordFieldProvider.notifier).state = false;
                                            _oldPasswordController.clear();
                                            _newPasswordController.clear();
                                            _confirmPasswordController.clear();
                                          },
                                          child: const Text('Annuler'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.lock, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Modifier votre mot de passe',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Assurez-vous que votre compte reste sécurisé',
                                    style: TextStyle(color: Colors.grey.shade500),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => ref.read(showPasswordFieldProvider.notifier).state = true,
                                      icon: const Icon(Icons.lock),
                                      label: const Text('Modifier le mot de passe'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEditing,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    if (isEditing) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: validator,
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              controller.text.isEmpty ? '—' : controller.text,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
  }
}