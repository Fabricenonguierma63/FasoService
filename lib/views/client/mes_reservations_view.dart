// ignore_for_file: control_flow_in_finally

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../models/reservation.dart';
import '../../models/service.dart';
import '../../models/prestataire.dart';
import '../../viewmodels/reservation_viewmodel.dart';
import '../../widgets/indicateur_chargement.dart';

class MesReservationsView extends StatefulWidget {
  const MesReservationsView({super.key});

  @override
  State<MesReservationsView> createState() => _MesReservationsViewState();
}

class _MesReservationsViewState extends State<MesReservationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final List<String> _tabs = ['En cours', 'Terminées', 'Annulées'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => _chargerReservations());
  }

  void _donnerAvis(
    Reservation reservation,
    Service service,
    Prestataire prestataire,
  ) {
    Navigator.pushNamed(
      context,
      '/donner_avis',
      arguments: {
        'reservation': reservation,
        'service': service,
        'prestataire': prestataire,
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerReservations() async {
    final reservationViewModel = Provider.of<ReservationViewModel>(
      context,
      listen: false,
    );
    setState(() {
      _isLoading = true;
    });
    try {
      await reservationViewModel.chargerReservationsClient();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Constants.erreurChargement),
          backgroundColor: Couleurs.erreur,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // En-tête avec titre
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mes Réservations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Onglets modernes
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white.withAlpha(51),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withAlpha(179),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule, size: 18),
                            const SizedBox(width: 6),
                            Text(_tabs[0]),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 18),
                            const SizedBox(width: 6),
                            Text(_tabs[1]),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cancel, size: 18),
                            const SizedBox(width: 6),
                            Text(_tabs[2]),
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
      ),
      body: _isLoading
          ? const Center(child: IndicateurChargement())
          : RefreshIndicator(
              onRefresh: _chargerReservations,
              color: Colors.orange,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReservationsList(
                    StatutReservation.enAttente,
                    StatutReservation.confirmee,
                  ),
                  _buildReservationsList(StatutReservation.terminee),
                  _buildReservationsList(StatutReservation.annulee),
                ],
              ),
            ),
    );
  }

  Widget _buildReservationsList(
    StatutReservation status1, [
    StatutReservation? status2,
  ]) {
    final reservationViewModel = Provider.of<ReservationViewModel>(context);
    final filteredReservations = reservationViewModel.reservationsClient.where((
      reservation,
    ) {
      if (status2 != null) {
        return reservation.statut == status1 || reservation.statut == status2;
      }
      return reservation.statut == status1;
    }).toList();

    if (filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withAlpha(26),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.orange.withAlpha(179),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune réservation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos réservations apparaîtront ici',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredReservations.length,
      itemBuilder: (context, index) {
        return _buildReservationCard(filteredReservations[index], context);
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation, BuildContext context) {
    final reservationViewModel = Provider.of<ReservationViewModel>(
      context,
      listen: false,
    );

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        reservationViewModel.getServiceById(reservation.serviceId),
        reservationViewModel.getPrestataireById(reservation.prestataireId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    "Erreur de chargement des données",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          );
        }

        final Service service = snapshot.data![0];
        final Prestataire prestataire = snapshot.data![1];

        final dateFormatter = DateFormat(Constants.formatDate);
        final heureFormatter = DateFormat(Constants.formatHeure);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 4,
            shadowColor: Colors.black.withAlpha(26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _afficherDetailsReservation(
                reservation,
                service,
                prestataire,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de la carte
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service.titre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatutBadge(reservation.statut),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Informations du prestataire
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.withAlpha(77),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: prestataire.photoProfil != null
                                ? NetworkImage(prestataire.photoProfil!)
                                : const AssetImage(Constants.imageProfilDefaut)
                                      as ImageProvider,
                            backgroundColor: Colors.orange.withAlpha(26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prestataire.nomComplet,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                prestataire.categories.join(', '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Informations de la réservation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                dateFormatter.format(reservation.dateService),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                heureFormatter.format(reservation.dateService),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.paid,
                                size: 20,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${reservation.montant.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Boutons d'action
                    if (reservation.statut == StatutReservation.enAttente ||
                        reservation.statut == StatutReservation.confirmee ||
                        reservation.statut == StatutReservation.terminee)
                      const SizedBox(height: 16),

                    if (reservation.statut == StatutReservation.enAttente)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _annulerReservation(reservation.id),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Annuler la réservation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.red[200]!),
                            ),
                          ),
                        ),
                      ),

                    if (reservation.statut == StatutReservation.confirmee)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _contacterPrestataire(prestataire),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Contacter le prestataire'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                    if (reservation.statut == StatutReservation.terminee)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _donnerAvis(reservation, service, prestataire),
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Donner mon avis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue[700],
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.blue[200]!),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatutBadge(StatutReservation statut) {
    late Color couleur;
    late String texte;
    late IconData icone;

    switch (statut) {
      case StatutReservation.enAttente:
        couleur = Colors.orange;
        texte = 'En attente';
        icone = Icons.schedule;
        break;
      case StatutReservation.confirmee:
        couleur = Colors.green;
        texte = 'Confirmée';
        icone = Icons.check_circle;
        break;
      case StatutReservation.annulee:
        couleur = Colors.red;
        texte = 'Annulée';
        icone = Icons.cancel;
        break;
      case StatutReservation.terminee:
        couleur = Colors.blue;
        texte = 'Terminée';
        icone = Icons.task_alt;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: couleur.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: couleur),
          const SizedBox(width: 4),
          Text(
            texte,
            style: TextStyle(
              color: couleur,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _contacterPrestataire(Prestataire prestataire) {
    // ignore: unused_local_variable
    final numero = prestataire.telephone;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ouverture de WhatsApp pour contacter ${prestataire.nomComplet}',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _afficherDetailsReservation(
    Reservation reservation,
    Service service,
    Prestataire prestataire,
  ) {
    // (Tu peux conserver le corps de cette méthode comme tu l'avais déjà)
  }

  Future<void> _annulerReservation(String reservationId) async {
    final reservationViewModel = Provider.of<ReservationViewModel>(
      context,
      listen: false,
    );

    bool confirmation =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Annuler la réservation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir annuler cette réservation ?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('NON', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OUI', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmation) {
      try {
        await reservationViewModel.annulerReservation(reservationId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réservation annulée avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
