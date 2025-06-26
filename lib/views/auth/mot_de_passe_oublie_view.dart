// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../configs/themes.dart';
import '../../viewmodels/authentification_viewmodel.dart';
import '../../widgets/bouton_principal.dart';
import '../../widgets/indicateur_chargement.dart';

class MotDePasseOublieView extends StatefulWidget {
  const MotDePasseOublieView({super.key});

  @override
  State<MotDePasseOublieView> createState() => _MotDePasseOublieViewState();
}

class _MotDePasseOublieViewState extends State<MotDePasseOublieView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _chargementEnCours = false;
  bool _emailEnvoye = false;
  String? _dernierEmailEnvoye; // Pour éviter les envois multiples

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _envoyerEmailReinitialisation() async {
    if (_formKey.currentState!.validate()) {
      // Vérifier si c'est le même email pour éviter le spam
      if (_dernierEmailEnvoye == _emailController.text.trim() && _emailEnvoye) {
        _afficherMessage(
          'Email déjà envoyé à cette adresse. Vérifiez votre boîte de réception.',
          estErreur: false,
        );
        return;
      }

      setState(() {
        _chargementEnCours = true;
      });

      try {
        final authViewModel = Provider.of<AuthentificationViewModel>(
          context,
          listen: false,
        );

        bool success = await authViewModel.reinitialiserMotDePasse(
          _emailController.text.trim(),
        );

        if (mounted) {
          if (success) {
            setState(() {
              _emailEnvoye = true;
              _dernierEmailEnvoye = _emailController.text.trim();
            });

            _afficherMessage(
              'Un email de réinitialisation a été envoyé à votre adresse.',
              estErreur: false,
            );
          } else {
            _afficherMessage(
              authViewModel.erreur ?? 'Erreur lors de l\'envoi de l\'email.',
              estErreur: true,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          _afficherMessage(
            'Erreur inattendue: ${e.toString()}',
            estErreur: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _chargementEnCours = false;
          });
        }
      }
    }
  }

  void _afficherMessage(String message, {required bool estErreur}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: estErreur ? Couleurs.erreur : Couleurs.succes,
        duration: Duration(seconds: estErreur ? 5 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _recommencer() {
    setState(() {
      _emailEnvoye = false;
      _dernierEmailEnvoye = null;
    });
    _emailController.clear();

    // Effacer les erreurs précédentes
    Provider.of<AuthentificationViewModel>(
      context,
      listen: false,
    ).effacerErreur();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Icône et titre
                _buildHeader(),
                const SizedBox(height: 40),

                if (!_emailEnvoye) ...[
                  _buildFormulaire(),
                ] else ...[
                  _buildSuccessContent(),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _emailEnvoye
                  ? Couleurs.succes.withAlpha(26)
                  : Couleurs.accent.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _emailEnvoye
                  ? Icons.mark_email_read_rounded
                  : Icons.lock_reset_rounded,
              size: 60,
              color: _emailEnvoye ? Couleurs.succes : Couleurs.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _emailEnvoye ? 'Email envoyé !' : 'Réinitialiser le mot de passe',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Couleurs.texte,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _emailEnvoye
                ? 'Vérifiez votre boîte email et suivez les instructions pour réinitialiser votre mot de passe.'
                : 'Entrez votre adresse email pour recevoir un lien de réinitialisation de mot de passe.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Couleurs.texteSecondaire),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaire() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Champ email avec validation améliorée
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => _envoyerEmailReinitialisation(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'exemple@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre email';
              }

              final email = value.trim();
              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
                return 'Veuillez entrer un email valide';
              }

              return null;
            },
          ),
          const SizedBox(height: 32),

          // Bouton d'envoi
          _chargementEnCours
              ? const Center(child: IndicateurChargement())
              : BoutonPrincipal(
                  onPressed: _envoyerEmailReinitialisation,
                  texte: 'Envoyer le lien',
                  icone: Icons.send_rounded,
                ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Informations supplémentaires
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Couleurs.blanc,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Couleurs.primaire.withAlpha(51),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Couleurs.primaire, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Conseils utiles',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Couleurs.primaire,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• Vérifiez votre dossier spam/courrier indésirable\n'
                '• L\'email peut prendre quelques minutes à arriver\n'
                '• Le lien expire après 24 heures\n'
                '• Email envoyé à: ${_dernierEmailEnvoye ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Couleurs.texteSecondaire,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bouton renvoyer
        OutlinedButton.icon(
          onPressed: _chargementEnCours ? null : _recommencer,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Essayer avec un autre email'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton retour à la connexion
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour à la connexion'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
