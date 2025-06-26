import 'package:flutter/material.dart';
import '../configs/themes.dart';

class IndicateurChargement extends StatelessWidget {
  final String? message;
  final double taille;
  final Color? couleur;
  final bool avecFond;
  final double opaciteFond;

  const IndicateurChargement({
    super.key,
    this.message,
    this.taille = 36.0,
    this.couleur,
    this.avecFond = false,
    this.opaciteFond = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenu = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: taille,
          height: taille,
          child: CircularProgressIndicator(
            color: couleur ?? Couleurs.primaire,
            strokeWidth: 3.0,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: avecFond ? Couleurs.blanc : Couleurs.texte,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (avecFond) {
      return Container(
        color: Colors.black.withOpacity(opaciteFond),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: BoxDecoration(
              color: Couleurs.secondaire,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: contenu,
          ),
        ),
      );
    }

    return Center(child: contenu);
  }
}

// Extension pour faciliter l'affichage de l'indicateur de chargement dans l'application
extension IndicateurChargementContextExtension on BuildContext {
  // Afficher l'indicateur de chargement en plein écran
  void afficherChargement({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: IndicateurChargement(message: message, avecFond: true),
          ),
    );
  }

  // Cacher l'indicateur de chargement
  void cacherChargement() {
    Navigator.of(this, rootNavigator: true).pop();
  }
}

// Widget pour afficher un indicateur de chargement lorsque la page est en cours de chargement
class PageChargement extends StatelessWidget {
  final String? message;

  const PageChargement({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IndicateurChargement(
          message: message ?? 'Chargement en cours...',
        ),
      ),
    );
  }
}

// Widget pour afficher un indicateur de chargement en remplacement d'une liste vide
class ChargementListe extends StatelessWidget {
  final String? message;

  const ChargementListe({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: IndicateurChargement(
          message: message ?? 'Chargement des données...',
          taille: 28.0,
        ),
      ),
    );
  }
}
