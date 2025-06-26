// ignore_for_file: use_build_context_synchronously

import 'package:faso_services/models/utilisateur.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../configs/themes.dart';
import '../../viewmodels/authentification_viewmodel.dart';
import '../../widgets/bouton_principal.dart';
import '../../widgets/indicateur_chargement.dart';
import 'inscription_view.dart';
import 'mot_de_passe_oublie_view.dart';

class ConnexionView extends StatefulWidget {
  const ConnexionView({super.key});

  @override
  State<ConnexionView> createState() => _ConnexionViewState();
}

class _ConnexionViewState extends State<ConnexionView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;
  bool _chargementEnCours = false;

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _connexion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _chargementEnCours = true;
      });

      try {
        bool success = await Provider.of<AuthentificationViewModel>(
          context,
          listen: false,
        ).connexion(_emailController.text, _motDePasseController.text);

        if (success) {
          final user = Provider.of<AuthentificationViewModel>(
            context,
            listen: false,
          ).utilisateur!;
          if (user.type == TypeUtilisateur.client) {
            Navigator.pushReplacementNamed(context, '/accueil');
          } else {
            Navigator.pushReplacementNamed(context, '/tableau_bord');
          }
        } else {
          final erreur = Provider.of<AuthentificationViewModel>(
            context,
            listen: false,
          ).erreur;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erreur ?? 'Erreur de connexion.'),
              backgroundColor: Couleurs.erreur,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo et titre
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Couleurs.primaire.withAlpha((26)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.handyman_rounded,
                            size: 60,
                            color: Couleurs.primaire,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'FasoServices',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Couleurs.primaire,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Services à domicile au Burkina Faso',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Couleurs.texteSecondaire),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Champ email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Entrez votre adresse email',
                      prefixIcon: const Icon(Icons.email_outlined),
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

                  // Champ mot de passe
                  TextFormField(
                    controller: _motDePasseController,
                    obscureText: !_motDePasseVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: 'Entrez votre mot de passe',
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
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Lien mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MotDePasseOublieView(),
                          ),
                        );
                      },
                      child: Text(
                        'Mot de passe oublié?',
                        style: TextStyle(
                          color: Couleurs.secondaire,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Bouton de connexion
                  _chargementEnCours
                      ? const Center(child: IndicateurChargement())
                      : BoutonPrincipal(
                          onPressed: _connexion,
                          texte: 'Se connecter',
                          icone: Icons.login,
                        ),
                  const SizedBox(height: 20),

                  // Bouton d'inscription
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InscriptionView(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Créer un compte'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
