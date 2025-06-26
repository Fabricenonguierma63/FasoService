import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../configs/constants.dart';
import '../../models/reservation.dart';
import '../../widgets/indicateur_chargement.dart';
import 'package:url_launcher/url_launcher.dart';

class DemandesView extends StatefulWidget {
  const DemandesView({super.key});

  @override
  State<DemandesView> createState() => _DemandesViewState();
}

class _DemandesViewState extends State<DemandesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = false;
  final List<String> _tabs = ['En attente', 'Confirmées', 'Terminées'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateReservationStatus(
    String reservationId,
    StatutReservation newStatus,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .update({
            'statut': newStatus == StatutReservation.confirmee
                ? 'confirmee'
                : newStatus == StatutReservation.annulee
                ? 'annulee'
                : newStatus == StatutReservation.terminee
                ? 'terminee'
                : 'en_attente',
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == StatutReservation.confirmee
                ? 'Réservation confirmée avec succès'
                : newStatus == StatutReservation.annulee
                ? 'Réservation refusée'
                : 'Réservation marquée comme terminée',
          ),
          backgroundColor: newStatus == StatutReservation.annulee
              ? Colors.red
              : Colors.green,
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
          content: const Text(
            'Erreur lors de la mise à jour de la réservation',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _contacterClient(String telephone) async {
    final Uri whatsappUrl = Uri.parse("https://wa.me/$telephone");
    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible d\'ouvrir WhatsApp'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Stream<QuerySnapshot> _getReservationsStream(StatutReservation status) {
    return _firestore
        .collection(Constants.reservationsCollection)
        .where('prestataireId', isEqualTo: _userId)
        .where('statut', isEqualTo: Reservation.statutToString(status))
        .orderBy('dateService', descending: false)
        .snapshots();
  }

  Future<Map<String, dynamic>> _getClientInfo(String clientId) async {
    try {
      DocumentSnapshot clientDoc = await _firestore
          .collection(Constants.usersCollection)
          .doc(clientId)
          .get();

      if (clientDoc.exists) {
        Map<String, dynamic> clientData =
            clientDoc.data() as Map<String, dynamic>;
        return {
          'nom': '${clientData['prenom']} ${clientData['nom']}',
          'telephone': clientData['telephone'],
          'photoProfil': clientData['photoProfil'],
        };
      }
      return {'nom': 'Client inconnu', 'telephone': '', 'photoProfil': null};
    } catch (e) {
      return {'nom': 'Client inconnu', 'telephone': '', 'photoProfil': null};
    }
  }

  Future<String> _getServiceName(String serviceId) async {
    try {
      DocumentSnapshot serviceDoc = await _firestore
          .collection(Constants.servicesCollection)
          .doc(serviceId)
          .get();

      if (serviceDoc.exists) {
        Map<String, dynamic> serviceData =
            serviceDoc.data() as Map<String, dynamic>;
        return serviceData['titre'] ?? 'Service inconnu';
      }
      return 'Service inconnu';
    } catch (e) {
      return 'Service inconnu';
    }
  }

  Widget _buildReservationCard(Reservation reservation) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getClientInfo(reservation.clientId),
      builder: (context, clientSnapshot) {
        return FutureBuilder<String>(
          future: _getServiceName(reservation.serviceId),
          builder: (context, serviceSnapshot) {
            if (clientSnapshot.connectionState == ConnectionState.waiting ||
                serviceSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black.withAlpha(
                    25,
                  ), // 0.1 opacity = alpha 25
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final String clientName =
                clientSnapshot.data?['nom'] ?? 'Client inconnu';
            final String clientPhone = clientSnapshot.data?['telephone'] ?? '';
            final String? clientPhoto = clientSnapshot.data?['photoProfil'];
            final String serviceName =
                serviceSnapshot.data ?? 'Service inconnu';

            final dateFormatter = DateFormat(Constants.formatDate);
            final heureFormatter = DateFormat(Constants.formatHeure);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withAlpha(
                  25,
                ), // 0.1 * 255 = 25.5 ≈ 25
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _afficherDetailsReservation(
                    reservation,
                    serviceName,
                    clientName,
                    clientPhone,
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
                                serviceName,
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

                        // Informations du client
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange.withAlpha(
                                    77,
                                  ), // 0.3 * 255 = 76.5 arrondi à 77
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: clientPhoto != null
                                    ? NetworkImage(clientPhoto)
                                    : const AssetImage(
                                            Constants.imageProfilDefaut,
                                          )
                                          as ImageProvider,
                                backgroundColor: Colors.orange.withAlpha(
                                  25,
                                ), // 0.1 * 255 = 25.5 arrondi à 25
                                child: clientPhoto == null
                                    ? Icon(
                                        Icons.person,
                                        color: Colors.orange[600],
                                        size: 24,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Client',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Prix
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(
                                  25,
                                ), // 0.1 = alpha 25
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.withAlpha(
                                    77,
                                  ), // 0.3 = alpha 77
                                ),
                              ),
                              child: Text(
                                '${reservation.montant.toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
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
                                    dateFormatter.format(
                                      reservation.dateService,
                                    ),
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
                                    heureFormatter.format(
                                      reservation.dateService,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              if (reservation.commentaire != null &&
                                  reservation.commentaire!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.note,
                                      size: 20,
                                      color: Colors.orange[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        reservation.commentaire!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Boutons d'action
                        const SizedBox(height: 16),
                        _buildActionButtons(reservation, clientPhone),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(Reservation reservation, String clientPhone) {
    if (reservation.statut == StatutReservation.enAttente) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Refuser'),
              onPressed: _isLoading
                  ? null
                  : () => _showConfirmationDialog(
                      'Refuser la demande',
                      'Êtes-vous sûr de vouloir refuser cette demande ?',
                      () => _updateReservationStatus(
                        reservation.id,
                        StatutReservation.annulee,
                      ),
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[200]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accepter'),
              onPressed: _isLoading
                  ? null
                  : () => _updateReservationStatus(
                      reservation.id,
                      StatutReservation.confirmee,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (reservation.statut == StatutReservation.confirmee) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Terminée'),
              onPressed: _isLoading
                  ? null
                  : () => _showConfirmationDialog(
                      'Marquer comme terminée',
                      'Confirmez-vous que ce service est terminé ?',
                      () => _updateReservationStatus(
                        reservation.id,
                        StatutReservation.terminee,
                      ),
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[700],
                side: BorderSide(color: Colors.blue[200]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('WhatsApp'),
              onPressed: clientPhone.isNotEmpty
                  ? () => _contacterClient(clientPhone)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (reservation.statut == StatutReservation.terminee) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.chat, size: 18),
          label: const Text('Contacter le client'),
          onPressed: clientPhone.isNotEmpty
              ? () => _contacterClient(clientPhone)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
        texte = 'Refusée';
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
        color: couleur.withAlpha(25), // équivalent à 0.1 d’opacité
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withAlpha(77)), // équivalent à 0.3
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

  Widget _buildReservationsList(StatutReservation status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReservationsStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: IndicateurChargement());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withAlpha(
                    178,
                  ), // au lieu de withOpacity(0.7)
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final reservations = snapshot.data?.docs ?? [];

        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withAlpha(
                      25,
                    ), // au lieu de withOpacity(0.1)
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: Colors.orange.withAlpha(178), // pour 0.7,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  status == StatutReservation.enAttente
                      ? 'Aucune demande en attente'
                      : status == StatutReservation.confirmee
                      ? 'Aucune réservation confirmée'
                      : 'Aucune réservation terminée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les nouvelles demandes apparaîtront ici',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservationData =
                reservations[index].data() as Map<String, dynamic>;
            final reservation = Reservation.fromMap({
              'id': reservations[index].id,
              ...reservationData,
            });

            return _buildReservationCard(reservation);
          },
        );
      },
    );
  }

  void _showConfirmationDialog(
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherDetailsReservation(
    Reservation reservation,
    String serviceName,
    String clientName,
    String clientPhone,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Détails de la réservation',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Ajouter ici les détails supplémentaires si nécessaire
            Text('Service: $serviceName'),
            Text('Client: $clientName'),
            Text('Téléphone: $clientPhone'),
            Text(
              'Date: ${DateFormat(Constants.formatDateHeure).format(reservation.dateService)}',
            ),
            Text('Montant: ${reservation.montant.toStringAsFixed(0)} FCFA'),
            if (reservation.commentaire != null &&
                reservation.commentaire!.isNotEmpty)
              Text('Note: ${reservation.commentaire}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
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
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Mes Demandes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Onglets modernes
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withAlpha(51), // ≈ 0.2
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withAlpha(179), // ≈ 0.7
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 4),
                            Text(_tabs[0]),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 16),
                            const SizedBox(width: 4),
                            Text(_tabs[1]),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.task_alt, size: 16),
                            const SizedBox(width: 4),
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReservationsList(StatutReservation.enAttente),
                _buildReservationsList(StatutReservation.confirmee),
                _buildReservationsList(StatutReservation.terminee),
              ],
            ),
    );
  }
}
