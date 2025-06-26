import 'package:flutter/material.dart';
import '../configs/constants.dart';
import '../configs/themes.dart';
import '../models/service.dart';

class CarteService extends StatelessWidget {
  final Service service;
  final String? nomPrestataire;
  final Function()? onTap;
  final bool showActions;

  const CarteService({
    super.key,
    required this.service,
    this.nomPrestataire,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap:
            onTap ??
            () {
              if (showActions) {
                Navigator.pushNamed(
                  context,
                  '/reservation',
                  arguments: {'serviceId': service.id},
                );
              }
            },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du service
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  service.photos.isNotEmpty
                      ? Image.network(
                          service.photos.first,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              Constants.imageServiceDefaut,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          Constants.imageServiceDefaut,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),

                  // Badge de disponibilité
                  if (!service.estDisponible)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: const Center(
                          child: Text(
                            'Non disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Badge de catégorie
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Couleurs.secondaire.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.categorie,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Prix
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Couleurs.primaire,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service.prix.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informations sur le service
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du service
                  Text(
                    service.titre,
                    style: Theme.of(context).textTheme.displaySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Nom du prestataire si fourni
                  if (nomPrestataire != null) ...[
                    Text(
                      'Par $nomPrestataire',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Couleurs.texteSecondaire,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Description
                  Text(
                    service.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Boutons d'action
                  if (showActions && service.estDisponible) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implémentation de l'ouverture WhatsApp
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Ouverture de WhatsApp..."),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Contacter'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/reservation',
                              arguments: {'serviceId': service.id},
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Réserver'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
