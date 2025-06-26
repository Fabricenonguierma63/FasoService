import 'package:flutter/material.dart';
import '../configs/themes.dart';

class BoutonPrincipal extends StatelessWidget {
  final String texte;
  final Future<void> Function()? onPressed;
  final IconData? icone;
  final bool estPlein;
  final bool estLarge;
  final bool estChargement;
  final Color? couleur;
  final double? largeur;
  final double? hauteur;

  const BoutonPrincipal({
    super.key,
    required this.texte,
    required this.onPressed,
    this.icone,
    this.estPlein = true,
    this.estLarge = false,
    this.estChargement = false,
    this.couleur,
    this.largeur,
    this.hauteur,
  });

  @override
  Widget build(BuildContext context) {
    final Color couleurBouton = couleur ?? Couleurs.primaire;
    final double hauteurBouton = hauteur ?? (estLarge ? 56.0 : 48.0);
    final double largeurBouton =
        largeur ?? (estLarge ? double.infinity : 200.0);

    if (estPlein) {
      return SizedBox(
        width: largeurBouton,
        height: hauteurBouton,
        child: ElevatedButton(
          onPressed:
              estChargement
                  ? null
                  : () async {
                    if (onPressed != null) {
                      await onPressed!();
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: couleurBouton,
            foregroundColor: Couleurs.blanc,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _contenuBouton(),
        ),
      );
    } else {
      return SizedBox(
        width: largeurBouton,
        height: hauteurBouton,
        child: OutlinedButton(
          onPressed:
              estChargement
                  ? null
                  : () async {
                    if (onPressed != null) {
                      await onPressed!();
                    }
                  },
          style: OutlinedButton.styleFrom(
            foregroundColor: couleurBouton,
            side: BorderSide(color: couleurBouton, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _contenuBouton(),
        ),
      );
    }
  }

  Widget _contenuBouton() {
    if (estChargement) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Couleurs.blanc,
          strokeWidth: 2.5,
        ),
      );
    }

    if (icone != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 20),
          const SizedBox(width: 8),
          Text(
            texte,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return Text(
      texte,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );
  }
}
