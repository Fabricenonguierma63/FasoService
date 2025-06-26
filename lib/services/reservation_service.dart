import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../configs/constants.dart';
import '../models/reservation.dart';
import '../models/service.dart';
import '../models/prestataire.dart';
import '../models/utilisateur.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer une nouvelle réservation
  Future<bool> creerReservation(Reservation reservation) async {
    try {
      // Générer un ID pour la réservation
      DocumentReference docRef = _firestore
          .collection(Constants.reservationsCollection)
          .doc();
      Reservation nouvelleReservation = reservation.copyWith(
        id: docRef.id,
        dateCreation: DateTime.now(),
      );

      // Enregistrer la réservation
      await docRef.set(nouvelleReservation.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la création de la réservation: $e");
      }
      return false;
    }
  }

  // Récupérer les réservations d'un client
  Future<List<Reservation>> getReservationsClient(String clientId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(Constants.reservationsCollection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('dateCreation', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération des réservations client: $e");
      }
      return [];
    }
  }

  // Récupérer les réservations d'un prestataire
  Future<List<Reservation>> getReservationsPrestataire(
    String prestataireId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(Constants.reservationsCollection)
          .where('prestataireId', isEqualTo: prestataireId)
          .orderBy('dateCreation', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          "Erreur lors de la récupération des réservations prestataire: $e",
        );
      }
      return [];
    }
  }

  // Mettre à jour le statut d'une réservation
  Future<bool> mettreAJourStatutReservation(
    String reservationId,
    StatutReservation nouveauStatut,
  ) async {
    try {
      await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .update({'statut': _statutToString(nouveauStatut)});
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du statut de la réservation: $e");
      }
      return false;
    }
  }

  // Récupérer les détails complets d'une réservation (avec service et prestataire)
  Future<Map<String, dynamic>?> getDetailsReservation(
    String reservationId,
  ) async {
    try {
      // Récupérer la réservation
      DocumentSnapshot reservationDoc = await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) {
        return null;
      }

      Reservation reservation = Reservation.fromMap({
        'id': reservationDoc.id,
        ...reservationDoc.data() as Map<String, dynamic>,
      });

      // Récupérer le service
      DocumentSnapshot serviceDoc = await _firestore
          .collection(Constants.servicesCollection)
          .doc(reservation.serviceId)
          .get();

      Service? service;
      if (serviceDoc.exists) {
        service = Service.fromMap({
          'id': serviceDoc.id,
          ...serviceDoc.data() as Map<String, dynamic>,
        });
      }

      // Récupérer le prestataire
      DocumentSnapshot prestataireDoc = await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(reservation.prestataireId)
          .get();

      Prestataire? prestataire;
      if (prestataireDoc.exists) {
        prestataire = Prestataire.fromMap({
          'id': prestataireDoc.id,
          ...prestataireDoc.data() as Map<String, dynamic>,
        });
      }

      // Récupérer le client
      DocumentSnapshot clientDoc = await _firestore
          .collection(Constants.usersCollection)
          .doc(reservation.clientId)
          .get();

      Utilisateur? client;
      if (clientDoc.exists) {
        client = Utilisateur.fromMap({
          'id': clientDoc.id,
          ...clientDoc.data() as Map<String, dynamic>,
        });
      }

      return {
        'reservation': reservation,
        'service': service,
        'prestataire': prestataire,
        'client': client,
      };
    } catch (e) {
      if (kDebugMode) {
        print(
          "Erreur lors de la récupération des détails de la réservation: $e",
        );
      }
      return null;
    }
  }

  // Méthode utilitaire pour convertir l'énumération en chaîne
  String _statutToString(StatutReservation statut) {
    switch (statut) {
      case StatutReservation.enAttente:
        return 'en_attente';
      case StatutReservation.confirmee:
        return 'confirmee';
      case StatutReservation.annulee:
        return 'annulee';
      case StatutReservation.terminee:
        return 'terminee';
    }
  }

  // Vérifier si une date est disponible pour un prestataire
  Future<bool> verifierDisponibilite(
    String prestataireId,
    DateTime date,
  ) async {
    try {
      // Récupérer toutes les réservations confirmées pour cette date
      final debutJournee = DateTime(date.year, date.month, date.day);
      final finJournee = debutJournee.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection(Constants.reservationsCollection)
          .where('prestataireId', isEqualTo: prestataireId)
          .where(
            'dateService',
            isGreaterThanOrEqualTo: debutJournee.millisecondsSinceEpoch,
          )
          .where('dateService', isLessThan: finJournee.millisecondsSinceEpoch)
          .where('statut', whereIn: ['confirmee', 'en_attente'])
          .get();

      // Vérifier chaque créneau horaire (simplification: on considère qu'une réservation prend 2h)
      for (var doc in snapshot.docs) {
        Reservation reservation = Reservation.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        // Vérifier si le créneau demandé chevauche une réservation existante
        int demandeDebut = date.millisecondsSinceEpoch;
        int demandeFin = date
            .add(const Duration(hours: 2))
            .millisecondsSinceEpoch;

        int reservationDebut = reservation.dateService.millisecondsSinceEpoch;
        int reservationFin = reservation.dateService
            .add(const Duration(hours: 2))
            .millisecondsSinceEpoch;

        if ((demandeDebut >= reservationDebut &&
                demandeDebut < reservationFin) ||
            (demandeFin > reservationDebut && demandeFin <= reservationFin) ||
            (demandeDebut <= reservationDebut &&
                demandeFin >= reservationFin)) {
          return false; // Chevauchement détecté
        }
      }

      return true; // Aucun chevauchement, créneau disponible
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la vérification de disponibilité: $e");
      }
      return false;
    }
  }
}
