import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../models/service.dart';
import '../../models/prestataire.dart';
import '../../viewmodels/reservation_viewmodel.dart';
import '../../widgets/bouton_principal.dart';
import '../../widgets/selecteur_date.dart';
import '../../widgets/indicateur_chargement.dart';

class ReservationView extends StatefulWidget {
  const ReservationView({super.key});

  @override
  State<ReservationView> createState() => _ReservationViewState();
}

class _ReservationViewState extends State<ReservationView> {
  DateTime? _dateSelectionnee;
  TimeOfDay? _heureSelectionnee;
  final TextEditingController _commentaireController = TextEditingController();
  bool _estEnChargement = false;

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les arguments passés à la page
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Service service = args['service'] as Service;
    final Prestataire prestataire = args['prestataire'] as Prestataire;

    return Scaffold(
      appBar: AppBar(title: const Text('Réserver un service')),
      body: Consumer<ReservationViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte de détails du service
                _construireCarteService(service, prestataire),

                const SizedBox(height: 24),

                // Sélection de la date
                Text(
                  'Choisir une date',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                SelecteurDate(
                  onDateChanged: (date) {
                    setState(() {
                      _dateSelectionnee = date;
                    });
                  },
                  labelText: 'Date du service',
                  dateInitiale: DateTime.now().add(const Duration(days: 1)),
                  dateMinimale: DateTime.now(),
                  dateMaximale: DateTime.now().add(const Duration(days: 30)),
                ),

                const SizedBox(height: 24),

                // Sélection de l'heure
                Text(
                  'Choisir une heure',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                _construireSelecteurHeure(context),

                const SizedBox(height: 24),

                // Champ commentaire
                Text(
                  'Commentaire (optionnel)',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentaireController,
                  decoration: const InputDecoration(
                    hintText: 'Instructions spécifiques pour le prestataire...',
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // Résumé de la réservation
                _construireResume(service),

                const SizedBox(height: 32),

                // Bouton de réservation
                _estEnChargement
                    ? const Center(child: IndicateurChargement())
                    : SizedBox(
                        width: double
                            .infinity, // Forcer le bouton à prendre toute la largeur disponible
                        child: BoutonPrincipal(
                          texte: 'Confirmer la réservation',
                          onPressed: () async => _confirmerReservation(
                            context,
                            viewModel,
                            service,
                            prestataire,
                          ),
                          icone: Icons.check_circle_outline,
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construireCarteService(Service service, Prestataire prestataire) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.titre,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, color: Couleurs.secondaire, size: 18),
                const SizedBox(width: 8),
                Text(
                  prestataire.nomComplet,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.category,
                  color: Couleurs.secondaire,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  service.categorie,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Couleurs.secondaire,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prestataire.adresse,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prix:', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '${service.prix.toStringAsFixed(0)} FCFA',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(color: Couleurs.primaire),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireSelecteurHeure(BuildContext context) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? heure = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (heure != null) {
          setState(() {
            _heureSelectionnee = heure;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Couleurs.blanc,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _heureSelectionnee != null
                  ? '${_heureSelectionnee!.hour.toString().padLeft(2, '0')}:${_heureSelectionnee!.minute.toString().padLeft(2, '0')}'
                  : 'Sélectionner une heure',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _heureSelectionnee != null
                    ? Couleurs.texte
                    : Couleurs.texteSecondaire,
              ),
            ),
            const Icon(Icons.access_time, color: Couleurs.secondaire),
          ],
        ),
      ),
    );
  }

  Widget _construireResume(Service service) {
    String dateFormatee = _dateSelectionnee != null
        ? DateFormat(Constants.formatDate).format(_dateSelectionnee!)
        : '---';
    String heureFormatee = _heureSelectionnee != null
        ? '${_heureSelectionnee!.hour.toString().padLeft(2, '0')}:${_heureSelectionnee!.minute.toString().padLeft(2, '0')}'
        : '---';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Couleurs.fond,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la réservation',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Service:', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  service.titre,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date:', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  dateFormatee,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Heure:', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  heureFormatee,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix total:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${service.prix.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Couleurs.primaire,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerReservation(
    BuildContext context,
    ReservationViewModel viewModel,
    Service service,
    Prestataire prestataire,
  ) async {
    // Vérifier que la date et l'heure sont sélectionnées
    if (_dateSelectionnee == null || _heureSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date et une heure'),
          backgroundColor: Couleurs.erreur,
        ),
      );
      return;
    }

    setState(() {
      _estEnChargement = true;
    });

    // Combiner la date et l'heure sélectionnées
    final DateTime dateService = DateTime(
      _dateSelectionnee!.year,
      _dateSelectionnee!.month,
      _dateSelectionnee!.day,
      _heureSelectionnee!.hour,
      _heureSelectionnee!.minute,
    );

    try {
      // Créer la réservation
      await viewModel.creerReservation(
        prestataireId: prestataire.id,
        serviceId: service.id,
        dateService: dateService,
        montant: service.prix,
        commentaire: _commentaireController.text,
      );

      // Afficher un message de succès
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(Constants.reservationSucces),
            backgroundColor: Couleurs.succes,
          ),
        );

        // Rediriger vers la page des réservations
        Navigator.pushReplacementNamed(context, '/mes_reservations');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Couleurs.erreur,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _estEnChargement = false;
        });
      }
    }
  }
}
