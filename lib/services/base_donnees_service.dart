//import 'package:faso_services/views/prestataire/disponibilites_view.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/time_slot.dart';
import '../configs/constants.dart';
import '../models/utilisateur.dart';
import '../models/prestataire.dart';
import '../models/service.dart';
import '../models/reservation.dart';
import '../models/avis.dart';

class BaseDonneesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _utilisateurs =>
      _firestore.collection(Constants.usersCollection);
  CollectionReference get _prestataires =>
      _firestore.collection(Constants.prestatairesCollection);
  CollectionReference get _services =>
      _firestore.collection(Constants.servicesCollection);
  CollectionReference get _reservations =>
      _firestore.collection(Constants.reservationsCollection);
  CollectionReference get _avis =>
      _firestore.collection(Constants.avisCollection);
  FirebaseFirestore get firestore => _firestore;

  // UTILISATEURS
  Future<Utilisateur?> obtenirUtilisateur(String id) async {
    try {
      DocumentSnapshot doc = await _utilisateurs.doc(id).get();
      if (doc.exists) {
        return Utilisateur.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération de l'utilisateur: $e");
      }
      return null;
    }
  }

  Future<bool> mettreAJourUtilisateur(Utilisateur utilisateur) async {
    try {
      await _utilisateurs.doc(utilisateur.id).update(utilisateur.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour de l'utilisateur: $e");
      }
      return false;
    }
  }

  // PRESTATAIRES
  Future<List<Prestataire>> obtenirPrestataires({
    int limite = 20,
    String? categorie,
    double? latitude,
    double? longitude,
    double? distanceMax,
    bool premiumEnPremier = true,
  }) async {
    try {
      Query query = _prestataires.limit(limite);

      // Filtrer par catégorie si spécifié
      if (categorie != null) {
        query = query.where('categories', arrayContains: categorie);
      }

      // Trier par premium puis par note
      if (premiumEnPremier) {
        query = query
            .orderBy('estPremium', descending: true)
            .orderBy('noteMoyenne', descending: true);
      } else {
        query = query.orderBy('noteMoyenne', descending: true);
      }

      QuerySnapshot snapshot = await query.get();

      List<Prestataire> prestataires = snapshot.docs
          .map(
            (doc) => Prestataire.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      // Filtrer par distance si les coordonnées sont fournies
      if (latitude != null && longitude != null && distanceMax != null) {
        prestataires = prestataires.where((prestataire) {
          double distance = prestataire.calculerDistance(latitude, longitude);
          return distance <= distanceMax;
        }).toList();
      }

      return prestataires;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération des prestataires: $e");
      }
      return [];
    }
  }

  Future<Prestataire?> obtenirPrestataire(String id) async {
    try {
      DocumentSnapshot doc = await _prestataires.doc(id).get();
      if (doc.exists) {
        return Prestataire.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération du prestataire: $e");
      }
      return null;
    }
  }

  Future<bool> creerOuMettreAJourPrestataire(Prestataire prestataire) async {
    try {
      await _prestataires.doc(prestataire.id).set(prestataire.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du prestataire: $e");
      }
      return false;
    }
  }

  // SERVICES
  Future<List<Service>> obtenirServices({
    String? prestataireId,
    String? categorie,
    bool seulementDisponibles = true,
  }) async {
    try {
      Query query = _services;

      if (prestataireId != null) {
        query = query.where('prestataireId', isEqualTo: prestataireId);
      }

      if (categorie != null) {
        query = query.where('categorie', isEqualTo: categorie);
      }

      if (seulementDisponibles) {
        query = query.where('estDisponible', isEqualTo: true);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) => Service.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération des services: $e");
      }
      return [];
    }
  }

  Future<Service?> obtenirService(String id) async {
    try {
      DocumentSnapshot doc = await _services.doc(id).get();
      if (doc.exists) {
        return Service.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération du service: $e");
      }
      return null;
    }
  }

  Future<String?> creerService(Service service) async {
    try {
      final mapSansId = service.toMap()..remove('id'); // éviter 'id': ''
      DocumentReference docRef = await _services.add(mapSansId);

      await docRef.update({'id': docRef.id}); // 🔁 cohérence Firestore
      if (kDebugMode) {
        print("✅ Service créé avec ID : ${docRef.id}");
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors de la création du service: $e");
      }
      return null;
    }
  }

  Future<bool> mettreAJourService(Service service) async {
    try {
      await _services.doc(service.id).update(service.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du service: $e");
      }
      return false;
    }
  }

  Future<bool> supprimerService(String id) async {
    try {
      await _services.doc(id).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la suppression du service: $e");
      }
      return false;
    }
  }

  // RÉSERVATIONS
  Future<List<Reservation>> obtenirReservationsClient(String clientId) async {
    try {
      QuerySnapshot snapshot = await _reservations
          .where('clientId', isEqualTo: clientId)
          .orderBy('dateService', descending: true)
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

  Future<List<Reservation>> obtenirReservationsPrestataire(
    String prestataireId,
  ) async {
    try {
      QuerySnapshot snapshot = await _reservations
          .where('prestataireId', isEqualTo: prestataireId)
          .orderBy('dateService', descending: true)
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

  Future<String?> creerReservation(Reservation reservation) async {
    try {
      DocumentReference doc = await _reservations.add(reservation.toMap());
      return doc.id;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la création de la réservation: $e");
      }
      return null;
    }
  }

  Future<bool> mettreAJourStatutReservation(
    String id,
    StatutReservation nouveauStatut,
  ) async {
    try {
      await _reservations.doc(id).update({
        'statut': Reservation.statutToString(nouveauStatut),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du statut de réservation: $e");
      }
      return false;
    }
  }

  // AVIS
  Future<List<Avis>> obtenirAvisPrestataire(String prestataireId) async {
    try {
      QuerySnapshot snapshot = await _avis
          .where('prestataireId', isEqualTo: prestataireId)
          .orderBy('dateCreation', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => Avis.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération des avis: $e");
      }
      return [];
    }
  }

  Future<String?> ajouterAvis(Avis avis) async {
    try {
      // Créer l'avis
      DocumentReference docRef = await _avis.add(avis.toMap());

      // Mettre à jour la note moyenne du prestataire
      DocumentSnapshot prestataireDoc = await _prestataires
          .doc(avis.prestataireId)
          .get();

      if (prestataireDoc.exists) {
        Map<String, dynamic> data =
            prestataireDoc.data() as Map<String, dynamic>;
        int nombreAvis = (data['nombreAvis'] ?? 0) + 1;
        double ancienneNote = (data['noteMoyenne'] ?? 0.0).toDouble();
        double nouvelleNote =
            ((ancienneNote * (nombreAvis - 1)) + avis.note) / nombreAvis;

        await _prestataires.doc(avis.prestataireId).update({
          'noteMoyenne': nouvelleNote,
          'nombreAvis': nombreAvis,
        });
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'ajout de l'avis: $e");
      }
      return null;
    }
  }

  // 🔍 Obtenir les disponibilités d’un prestataire
  Future<Map<DateTime, List<TimeSlot>>> getDisponibilites(
    String prestataireId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('disponibilites')
          .doc(prestataireId)
          .collection('jours')
          .get();

      final Map<DateTime, List<TimeSlot>> disponibilites = {};

      for (var doc in snapshot.docs) {
        final jourKey = doc.id; // format attendu : '2025-05-20'
        final date = DateTime.tryParse(jourKey);
        if (date != null) {
          final data = doc.data();
          final creneaux = (data['creneaux'] as List<dynamic>? ?? [])
              .map((e) => TimeSlot.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          disponibilites[date] = creneaux;
        }
      }

      return disponibilites;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur getDisponibilites: $e');
      }
      return {};
    }
  }

  // ✅ Enregistrer les disponibilités pour un jour donné
  Future<void> setDisponibilites(
    String prestataireId,
    DateTime jour,
    List<TimeSlot> creneaux,
  ) async {
    try {
      final jourKey =
          '${jour.year.toString().padLeft(4, '0')}-${jour.month.toString().padLeft(2, '0')}-${jour.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('disponibilites')
          .doc(prestataireId)
          .collection('jours')
          .doc(jourKey)
          .set({'creneaux': creneaux.map((c) => c.toMap()).toList()});
    } catch (e) {
      if (kDebugMode) {
        print('Erreur setDisponibilites: $e');
      }
    }
  }

  // Ajouter cette méthode pour obtenir seulement les prestataires avec coordonnées :
  Future<List<Prestataire>> obtenirPrestatairesAvecCoordonnees() async {
    try {
      QuerySnapshot snapshot = await _prestataires
          .where('latitude', isNull: false)
          .where('longitude', isNull: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => Prestataire.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .where(
            (prestataire) =>
                prestataire.latitude != null && prestataire.longitude != null,
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          "Erreur lors de la récupération des prestataires avec coordonnées: $e",
        );
      }
      return [];
    }
  }
}
