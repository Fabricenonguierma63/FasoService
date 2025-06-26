import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/reservation.dart';
import '../models/service.dart';
import '../models/prestataire.dart';
import '../models/utilisateur.dart';
import '../services/base_donnees_service.dart';
import '../configs/constants.dart';

class ReservationViewModel with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Variables d'état
  bool _chargement = false;
  bool _erreur = false;
  String _messageErreur = '';
  List<Reservation> _mesReservations = [];
  List<Reservation> _reservationsRecues = [];

  ReservationViewModel(BaseDonneesService read);

  // Getters
  bool get chargement => _chargement;
  bool get erreur => _erreur;
  String get messageErreur => _messageErreur;
  List<Reservation> get reservationsClient => _mesReservations;
  List<Reservation> get reservationsRecues => _reservationsRecues;

  // Récupérer les réservations d'un client
  Future<void> chargerReservationsClient() async {
    _setChargement(true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Utilisateur non connecté");
      }

      final snapshot = await _firestore
          .collection(Constants.reservationsCollection)
          .where('clientId', isEqualTo: userId)
          .orderBy('dateService', descending: true)
          .get();

      _mesReservations = snapshot.docs
          .map((doc) {
            try {
              return Reservation.fromMap({'id': doc.id, ...doc.data()});
            } catch (e) {
              if (kDebugMode) {
                print('Erreur lors du parsing de la réservation ${doc.id}: $e');
              }
              return null;
            }
          })
          .where((reservation) => reservation != null)
          .cast<Reservation>()
          .toList();

      _setErreur(false, '');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans chargerReservationsClient: $e');
      }
      _setErreur(true, "Erreur lors du chargement des réservations: $e");
      // Ne pas réinitialiser la liste en cas d'erreur, garder les données existantes
      if (_mesReservations.isEmpty) {
        _mesReservations = [];
      }
    } finally {
      _setChargement(false);
    }
  }

  // Récupérer les réservations reçues par un prestataire
  Future<void> chargerReservationsPrestataire() async {
    _setChargement(true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Utilisateur non connecté");
      }

      final snapshot = await _firestore
          .collection(Constants.reservationsCollection)
          .where('prestataireId', isEqualTo: userId)
          .orderBy('dateService', descending: true)
          .get();

      _reservationsRecues = snapshot.docs
          .map((doc) {
            try {
              return Reservation.fromMap({'id': doc.id, ...doc.data()});
            } catch (e) {
              if (kDebugMode) {
                print('Erreur lors du parsing de la réservation ${doc.id}: $e');
              }
              return null;
            }
          })
          .where((reservation) => reservation != null)
          .cast<Reservation>()
          .toList();

      _setErreur(false, '');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans chargerReservationsPrestataire: $e');
      }
      _setErreur(true, "Erreur lors du chargement des réservations: $e");
      // Ne pas réinitialiser la liste en cas d'erreur, garder les données existantes
      if (_reservationsRecues.isEmpty) {
        _reservationsRecues = [];
      }
    } finally {
      _setChargement(false);
    }
  }

  // Créer une nouvelle réservation
  Future<bool> creerReservation({
    required String prestataireId,
    required String serviceId,
    required DateTime dateService,
    required double montant,
    String? commentaire,
  }) async {
    _setChargement(true);
    try {
      final clientId = _auth.currentUser?.uid;
      if (clientId == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Générer un ID unique pour la réservation
      final String reservationId = const Uuid().v4();

      // Créer la réservation
      final nouvelleReservation = Reservation(
        id: reservationId,
        clientId: clientId,
        prestataireId: prestataireId,
        serviceId: serviceId,
        dateReservation: DateTime.now(),
        dateService: dateService,
        statut: StatutReservation.enAttente,
        montant: montant,
        commentaire: commentaire,
        paiementEffectue: false,
        dateCreation: DateTime.now(),
      );

      // Enregistrer dans Firestore
      await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .set(nouvelleReservation.toMap());

      _setErreur(false, '');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans creerReservation: $e');
      }
      _setErreur(true, "Erreur lors de la création de la réservation: $e");
      return false;
    } finally {
      _setChargement(false);
    }
  }

  // Mettre à jour le statut d'une réservation
  Future<bool> mettreAJourStatutReservation(
    String reservationId,
    StatutReservation nouveauStatut,
  ) async {
    _setChargement(true);
    try {
      await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .update({'statut': _statutToString(nouveauStatut)});

      // Mettre à jour la liste locale seulement si elle n'est pas null
      if (_mesReservations.isNotEmpty &&
          _mesReservations.any((r) => r.id == reservationId)) {
        final index = _mesReservations.indexWhere((r) => r.id == reservationId);
        if (index != -1) {
          _mesReservations[index] = _mesReservations[index].copyWith(
            statut: nouveauStatut,
          );
        }
      }

      if (_reservationsRecues.isNotEmpty &&
          _reservationsRecues.any((r) => r.id == reservationId)) {
        final index = _reservationsRecues.indexWhere(
          (r) => r.id == reservationId,
        );
        if (index != -1) {
          _reservationsRecues[index] = _reservationsRecues[index].copyWith(
            statut: nouveauStatut,
          );
        }
      }

      _setErreur(false, '');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans mettreAJourStatutReservation: $e');
      }
      _setErreur(true, "Erreur lors de la mise à jour du statut: $e");
      return false;
    } finally {
      _setChargement(false);
      notifyListeners();
    }
  }

  // Marquer une réservation comme payée
  Future<bool> marquerCommePaye(String reservationId) async {
    _setChargement(true);
    try {
      await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .update({'paiementEffectue': true});

      // Mettre à jour la liste locale seulement si elle n'est pas null
      if (_mesReservations.isNotEmpty &&
          _mesReservations.any((r) => r.id == reservationId)) {
        final index = _mesReservations.indexWhere((r) => r.id == reservationId);
        if (index != -1) {
          _mesReservations[index] = _mesReservations[index].copyWith(
            paiementEffectue: true,
          );
        }
      }

      if (_reservationsRecues.isNotEmpty &&
          _reservationsRecues.any((r) => r.id == reservationId)) {
        final index = _reservationsRecues.indexWhere(
          (r) => r.id == reservationId,
        );
        if (index != -1) {
          _reservationsRecues[index] = _reservationsRecues[index].copyWith(
            paiementEffectue: true,
          );
        }
      }

      _setErreur(false, '');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans marquerCommePaye: $e');
      }
      _setErreur(true, "Erreur lors du marquage comme payé: $e");
      return false;
    } finally {
      _setChargement(false);
      notifyListeners();
    }
  }

  // Récupérer une réservation par son ID
  Future<Reservation?> obtenirReservation(String reservationId) async {
    try {
      final doc = await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Reservation.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans obtenirReservation: $e');
      }
      _setErreur(true, "Erreur lors de la récupération de la réservation: $e");
      return null;
    }
  }

  // Obtenir les détails d'un service pour une réservation
  Future<Service?> obtenirServicePourReservation(String serviceId) async {
    try {
      final doc = await _firestore
          .collection(Constants.servicesCollection)
          .doc(serviceId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Service.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans obtenirServicePourReservation: $e');
      }
      _setErreur(true, "Erreur lors de la récupération du service: $e");
      return null;
    }
  }

  // Obtenir les détails d'un prestataire pour une réservation
  Future<Prestataire?> obtenirPrestatairePourReservation(
    String prestataireId,
  ) async {
    try {
      final doc = await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(prestataireId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Prestataire.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans obtenirPrestatairePourReservation: $e');
      }
      _setErreur(true, "Erreur lors de la récupération du prestataire: $e");
      return null;
    }
  }

  // Obtenir les détails d'un client pour une réservation
  Future<Utilisateur?> obtenirClientPourReservation(String clientId) async {
    try {
      final doc = await _firestore
          .collection(Constants.usersCollection)
          .doc(clientId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Utilisateur.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans obtenirClientPourReservation: $e');
      }
      _setErreur(true, "Erreur lors de la récupération du client: $e");
      return null;
    }
  }

  // Utility method to convert StatutReservation to string
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

  // Helpers for state management
  void _setChargement(bool valeur) {
    _chargement = valeur;
    notifyListeners();
  }

  void _setErreur(bool valeur, String message) {
    _erreur = valeur;
    _messageErreur = message;
    if (valeur) {
      if (kDebugMode) {
        print('Erreur ReservationViewModel: $message');
      }
    }
    notifyListeners();
  }

  Future<void> annulerReservation(String reservationId) async {
    _setChargement(true);
    try {
      await _firestore
          .collection(Constants.reservationsCollection)
          .doc(reservationId)
          .update({'statut': _statutToString(StatutReservation.annulee)});

      // Mettre à jour localement
      if (_mesReservations.isNotEmpty) {
        final index = _mesReservations.indexWhere((r) => r.id == reservationId);
        if (index != -1) {
          _mesReservations[index] = _mesReservations[index].copyWith(
            statut: StatutReservation.annulee,
          );
        }
      }

      if (_reservationsRecues.isNotEmpty) {
        final index = _reservationsRecues.indexWhere(
          (r) => r.id == reservationId,
        );
        if (index != -1) {
          _reservationsRecues[index] = _reservationsRecues[index].copyWith(
            statut: StatutReservation.annulee,
          );
        }
      }

      _setErreur(false, '');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur dans annulerReservation: $e');
      }
      _setErreur(true, "Erreur lors de l'annulation de la réservation : $e");
      rethrow;
    } finally {
      _setChargement(false);
      notifyListeners();
    }
  }

  Future<Service?> getServiceById(String id) async {
    return await obtenirServicePourReservation(id);
  }

  Future<Prestataire?> getPrestataireById(String id) async {
    return await obtenirPrestatairePourReservation(id);
  }

  // Méthode pour réinitialiser les erreurs
  void clearError() {
    _setErreur(false, '');
  }

  // Méthode pour vérifier si les données sont chargées
  bool get hasData =>
      _mesReservations.isNotEmpty || _reservationsRecues.isNotEmpty;
}
