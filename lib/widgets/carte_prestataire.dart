import 'package:flutter/material.dart';
import '../configs/constants.dart';
import '../configs/themes.dart';
import '../models/prestataire.dart';

class CartePrestataire extends StatelessWidget {
  final Prestataire prestataire;
  final double? distanceEnKm;
  final bool estCompact;
  final VoidCallback? onTap;

  const CartePrestataire({
    super.key,
    required this.prestataire,
    this.distanceEnKm,
    this.estCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Couleurs.blanc, Couleurs.fond],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Couleurs.primaire.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            splashColor: Couleurs.primaire.withAlpha(25),
            highlightColor: Couleurs.primaire.withAlpha(13),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildModernLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contenu principal à gauche
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(context),
              const SizedBox(height: 16),
              _buildCategoriesSection(context),
              const SizedBox(height: 16),
              _buildStatsSection(context),
              if (!estCompact && prestataire.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDescriptionSection(context),
              ],
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Photo et badges à droite
        Expanded(flex: 2, child: _buildPhotoSection(context)),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom avec style moderne
        Text(
          prestataire.nomComplet,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Couleurs.texte,
            height: 1.1,
            letterSpacing: -0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Status et note en ligne
        Row(
          children: [
            _buildStatusChip(),
            const SizedBox(width: 12),
            _buildRatingBadge(context),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: prestataire.estDisponible
            ? Couleurs.succes
            : Couleurs.texteSecondaire,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (prestataire.estDisponible
                        ? Couleurs.succes
                        : Couleurs.texteSecondaire)
                    .withAlpha(64),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Couleurs.blanc,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            prestataire.estDisponible ? 'Disponible' : 'Occupé',
            style: const TextStyle(
              color: Couleurs.blanc,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Couleurs.accent, Couleurs.primaire]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Couleurs.accent.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Couleurs.blanc, size: 14),
          const SizedBox(width: 4),
          Text(
            prestataire.noteMoyenne.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Couleurs.blanc,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prestataire.categories.take(3).map((categorie) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Couleurs.primaire.withAlpha(25),
                Couleurs.primaire.withAlpha(13),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Couleurs.primaire.withAlpha(51),
              width: 1.5,
            ),
          ),
          child: Text(
            categorie,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Couleurs.primaire.withAlpha(204),
              letterSpacing: 0.2,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.reviews_rounded,
          label: '${prestataire.nombreAvis}',
          sublabel: 'avis',
          color: Couleurs.secondaire,
        ),

        const SizedBox(width: 16),

        if (distanceEnKm != null)
          _buildStatChip(
            icon: Icons.near_me_rounded,
            label: distanceEnKm!.toStringAsFixed(1),
            sublabel: 'km',
            color: Couleurs.accent,
          ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(38), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: ' $sublabel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Couleurs.fond,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Couleurs.texteSecondaire.withAlpha(51),
          width: 1,
        ),
      ),
      child: Text(
        prestataire.description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Couleurs.texteSecondaire,
          height: 1.5,
          fontSize: 13,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Column(
      children: [
        // Photo avec overlay moderne
        Container(
          height: estCompact ? 120 : 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image avec traitement d'erreur
                prestataire.photoProfil != null
                    ? Image.network(
                        prestataire.photoProfil!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultImage();
                        },
                      )
                    : _buildDefaultImage(),

                // Overlay moderne avec dégradé
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(76)],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),

                // Badges flottants
                _buildFloatingBadges(),
              ],
            ),
          ),
        ),

        if (!estCompact) ...[
          const SizedBox(height: 12),
          _buildQuickActions(context),
        ],
      ],
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Couleurs.primaire.withAlpha(102),
            Couleurs.secondaire.withAlpha(153),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image par défaut depuis les assets
          Image.asset(
            Constants.imageProfilDefaut,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Fallback vers l'icône si l'image n'existe pas
              return Icon(
                Icons.person_rounded,
                size: 40,
                color: Couleurs.blanc.withAlpha(204),
              );
            },
          ),
          // Overlay léger pour maintenir la cohérence visuelle
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Couleurs.texte.withAlpha(25)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadges() {
    return Stack(
      children: [
        // Badge Premium
        if (prestataire.estPremium)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Couleurs.accent, Couleurs.primaire],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Couleurs.accent.withAlpha(102),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.diamond, color: Couleurs.blanc, size: 12),
            ),
          ),

        // Badge de vérification
        if (prestataire.estVerifieProfessionnellement)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Couleurs.secondaire,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Couleurs.secondaire.withAlpha(102),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified,
                color: Couleurs.blanc,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Couleurs.primaire.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Couleurs.primaire.withAlpha(51),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.message_rounded,
              color: Couleurs.primaire,
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Couleurs.succes.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Couleurs.succes.withAlpha(51),
                width: 1,
              ),
            ),
            child: Icon(Icons.phone_rounded, color: Couleurs.succes, size: 18),
          ),
        ),
      ],
    );
  }
}
