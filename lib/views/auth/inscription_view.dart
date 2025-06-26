import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../configs/themes.dart';
import '../../models/utilisateur.dart';
import '../../viewmodels/authentification_viewmodel.dart';
import '../../widgets/bouton_principal.dart';
import '../../widgets/indicateur_chargement.dart';

class InscriptionView extends StatefulWidget {
  const InscriptionView({super.key});

  @override
  State<InscriptionView> createState() => _InscriptionViewState();
}

class _InscriptionViewState extends State<InscriptionView> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmerMotDePasseController = TextEditingController();

  bool _motDePasseVisible = false;
  bool _confirmerMotDePasseVisible = false;
  bool _chargementEnCours = false;
  TypeUtilisateur _typeUtilisateur = TypeUtilisateur.client;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _motDePasseController.dispose();
    _confirmerMotDePasseController.dispose();
    super.dispose();
  }

  Future<void> _inscription() async {
    if (_formKey.currentState!.validate()) {
      if (_motDePasseController.text != _confirmerMotDePasseController.text) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Les mots de passe ne correspondent pas."),
            backgroundColor: Couleurs.erreur,
          ),
        );
        return;
      }

      setState(() {
        _chargementEnCours = true;
      });

      try {
        bool success =
            await Provider.of<AuthentificationViewModel>(
              context,
              listen: false,
            ).inscription(
              nom: _nomController.text,
              prenom: _prenomController.text,
              email: _emailController.text,
              telephone: _telephoneController.text,
              motDePasse: _motDePasseController.text,
              type: _typeUtilisateur,
            );
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription réussie! Veuillez vous connectez.'),
              backgroundColor: Couleurs.succes,
            ),
          );
          Navigator.pop(context);
        } else {
          final erreur = Provider.of<AuthentificationViewModel>(
            context,
            listen: false,
          ).erreur;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erreur ?? 'Erreur d\'inscription.'),
              backgroundColor: Couleurs.erreur,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'inscription: ${e.toString()}'),
            backgroundColor: Couleurs.erreur,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _chargementEnCours = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type d'utilisateur
                Text(
                  'Vous êtes:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Sélection du type d'utilisateur
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeUtilisateurCard(
                        type: TypeUtilisateur.client,
                        icon: Icons.person,
                        title: 'Client',
                        description: 'Je souhaite trouver des services',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTypeUtilisateurCard(
                        type: TypeUtilisateur.prestataire,
                        icon: Icons.handyman,
                        title: 'Prestataire',
                        description: 'Je souhaite offrir mes services',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 🆕 Séparateur
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: Couleurs.texteSecondaire,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Informations personnelles
                Text(
                  'Informations personnelles',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Prénom
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom(s)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre prénom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nom
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    if (value.length < 8) {
                      return 'Numéro de téléphone invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sécurité
                Text(
                  'Sécurité',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _motDePasseController,
                  obscureText: !_motDePasseVisible,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _motDePasseVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Couleurs.texteSecondaire,
                      ),
                      onPressed: () {
                        setState(() {
                          _motDePasseVisible = !_motDePasseVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmer mot de passe
                TextFormField(
                  controller: _confirmerMotDePasseController,
                  obscureText: !_confirmerMotDePasseVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmerMotDePasseVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Couleurs.texteSecondaire,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmerMotDePasseVisible =
                              !_confirmerMotDePasseVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _motDePasseController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Bouton d'inscription classique
                _chargementEnCours
                    ? const Center(child: IndicateurChargement())
                    : BoutonPrincipal(
                        onPressed: _inscription,
                        texte: 'S\'inscrire',
                        icone: Icons.check_circle_outline,
                      ),
                const SizedBox(height: 24),

                // Lien vers la connexion
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            color: Couleurs.secondaire,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeUtilisateurCard({
    required TypeUtilisateur type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _typeUtilisateur == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _typeUtilisateur = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Couleurs.primaire : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Couleurs.primaire.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Couleurs.primaire.withOpacity(0.2)
                    : Colors.grey.shade100,
              ),
              child: Icon(
                icon,
                color: isSelected ? Couleurs.primaire : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Couleurs.primaire : Couleurs.texte,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Couleurs.texteSecondaire),
            ),
          ],
        ),
      ),
    );
  }
}
