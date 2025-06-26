import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/prestataire.dart';
import '../models/service.dart';
import '../models/avis.dart';
import '../configs/constants.dart';

class PrestataireService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtenir un prestataire par son ID
  Future<Prestataire?> getPrestataireById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(id)
          .get();

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

  // Rechercher des prestataires par catégorie
  Future<List<Prestataire>> rechercherPrestataires({
    String? categorie,
    String? motCle,
    double? latitude,
    double? longitude,
    double? rayonKm = 10.0,
    bool premiumFirst = true,
  }) async {
    try {
      Query query = _firestore.collection(Constants.prestatairesCollection);

      // Filtrer par catégorie si spécifiée
      if (categorie != null && categorie.isNotEmpty) {
        query = query.where('categories', arrayContains: categorie);
      }

      // Exécuter la requête
      QuerySnapshot snapshot = await query.get();

      List<Prestataire> prestataires = snapshot.docs
          .map(
            (doc) => Prestataire.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      // Filtrer par mot-clé si spécifié
      if (motCle != null && motCle.isNotEmpty) {
        final motCleLower = motCle.toLowerCase();
        prestataires = prestataires.where((p) {
          return p.nom.toLowerCase().contains(motCleLower) ||
              p.prenom.toLowerCase().contains(motCleLower) ||
              p.description.toLowerCase().contains(motCleLower) ||
              p.adresse.toLowerCase().contains(motCleLower);
        }).toList();
      }

      // Filtrer par distance si latitude et longitude spécifiées
      if (latitude != null && longitude != null) {
        prestataires = prestataires.where((p) {
          final distance = p.calculerDistance(latitude, longitude);
          return distance <= (rayonKm ?? 10.0);
        }).toList();

        // Trier par distance
        prestataires.sort((a, b) {
          final distanceA = a.calculerDistance(latitude, longitude);
          final distanceB = b.calculerDistance(latitude, longitude);
          return distanceA.compareTo(distanceB);
        });
      }

      // Mettre les prestataires premium en premier si demandé
      if (premiumFirst) {
        prestataires.sort((a, b) {
          if (a.estPremium && !b.estPremium) return -1;
          if (!a.estPremium && b.estPremium) return 1;
          return 0;
        });
      }

      return prestataires;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la recherche de prestataires: $e");
      }
      return [];
    }
  }

  // Obtenir les avis d'un prestataire
  Future<List<Avis>> getAvisPrestataire(String prestataireId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(Constants.avisCollection)
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

  // Obtenir les services d'un prestataire
  Future<List<Service>> getServicesPrestataire(String prestataireId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(Constants.servicesCollection)
          .where('prestataireId', isEqualTo: prestataireId)
          .orderBy('dateCreation', descending: true)
          .get();

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

  // Ajouter ou mettre à jour un service
  Future<bool> enregistrerService(Service service, {File? photoFile}) async {
    try {
      // Ajouter l'image au storage si spécifiée
      if (photoFile != null) {
        String imageUrl = await _uploadImage(
          photoFile,
          'services/${service.prestataireId}/${DateTime.now().millisecondsSinceEpoch}',
        );

        List<String> photos = [...service.photos];
        photos.add(imageUrl);
        service = service.copyWith(photos: photos);
      }

      // Déterminer s'il s'agit d'un ajout ou d'une mise à jour
      if (service.id.isEmpty) {
        // Générer un ID
        DocumentReference docRef = _firestore
            .collection(Constants.servicesCollection)
            .doc();
        Service nouveauService = service.copyWith(
          id: docRef.id,
          dateCreation: DateTime.now(),
          dateModification: DateTime.now(),
        );

        await docRef.set(nouveauService.toMap());
      } else {
        // Mise à jour
        Service serviceModifie = service.copyWith(
          dateModification: DateTime.now(),
        );

        await _firestore
            .collection(Constants.servicesCollection)
            .doc(service.id)
            .update(serviceModifie.toMap());
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'enregistrement du service: $e");
      }
      return false;
    }
  }

  // Ajouter un avis
  Future<bool> ajouterAvis(Avis avis, {List<File>? photosFichiers}) async {
    try {
      // Ajouter les images au storage si spécifié
      List<String> photosUrls = [];
      if (photosFichiers != null && photosFichiers.isNotEmpty) {
        for (var i = 0; i < photosFichiers.length; i++) {
          String imageUrl = await _uploadImage(
            photosFichiers[i],
            'avis/${avis.prestataireId}/${DateTime.now().millisecondsSinceEpoch}_$i',
          );
          photosUrls.add(imageUrl);
        }
      }

      // Générer un ID pour l'avis
      DocumentReference docRef = _firestore
          .collection(Constants.avisCollection)
          .doc();
      Avis nouvelAvis = avis.copyWith(
        id: docRef.id,
        photos: photosUrls,
        dateCreation: DateTime.now(),
      );

      // Enregistrer l'avis
      await docRef.set(nouvelAvis.toMap());

      // Mettre à jour la note moyenne et le nombre d'avis du prestataire
      await _mettreAJourNotePrestataireApresAvis(avis.prestataireId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'ajout de l'avis: $e");
      }
      return false;
    }
  }

  // Mettre à jour la note d'un prestataire
  Future<void> _mettreAJourNotePrestataireApresAvis(
    String prestataireId,
  ) async {
    try {
      // Récupérer tous les avis du prestataire
      QuerySnapshot avisSnapshot = await _firestore
          .collection(Constants.avisCollection)
          .where('prestataireId', isEqualTo: prestataireId)
          .get();

      int nombreAvis = avisSnapshot.docs.length;
      double sommeNotes = 0;

      // Calculer la somme des notes
      for (var doc in avisSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        sommeNotes += (data['note'] ?? 0).toDouble();
      }

      // Calculer la moyenne
      double noteMoyenne = nombreAvis > 0 ? sommeNotes / nombreAvis : 0;

      // Mettre à jour le prestataire
      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(prestataireId)
          .update({'noteMoyenne': noteMoyenne, 'nombreAvis': nombreAvis});
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour de la note du prestataire: $e");
      }
    }
  }

  // Mettre à jour les informations du prestataire
  Future<bool> mettreAJourPrestataire(
    Prestataire prestataire, {
    File? photoProfilFile,
    List<File>? photosPortfolioFiles,
  }) async {
    try {
      // Ajouter la photo de profil au storage si spécifiée
      if (photoProfilFile != null) {
        String imageUrl = await _uploadImage(
          photoProfilFile,
          'profils/${prestataire.id}',
        );
        prestataire = prestataire.copierAvec(photoProfil: imageUrl);
      }

      // Ajouter les photos du portfolio au storage si spécifiées
      if (photosPortfolioFiles != null && photosPortfolioFiles.isNotEmpty) {
        List<String> photosUrls = [...prestataire.photosPortfolio];

        for (var i = 0; i < photosPortfolioFiles.length; i++) {
          String imageUrl = await _uploadImage(
            photosPortfolioFiles[i],
            'portfolios/${prestataire.id}/${DateTime.now().millisecondsSinceEpoch}_$i',
          );
          photosUrls.add(imageUrl);
        }

        prestataire = prestataire.copierAvec(photosPortfolio: photosUrls);
      }

      // Mettre à jour le prestataire
      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(prestataire.id)
          .update(prestataire.toMap());

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du prestataire: $e");
      }
      return false;
    }
  }

  // Méthode pour uploader une image
  Future<String> _uploadImage(File file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'upload de l'image: $e");
      }
      rethrow;
    }
  }

  // Mettre à jour le statut premium d'un prestataire
  Future<bool> souscrireAbonnementPremium(
    String prestataireId,
    int nombreMois,
  ) async {
    try {
      // Récupérer le prestataire actuel
      DocumentSnapshot docPrestataire = await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(prestataireId)
          .get();

      if (!docPrestataire.exists) {
        return false;
      }

      Prestataire prestataire = Prestataire.fromMap({
        'id': docPrestataire.id,
        ...docPrestataire.data() as Map<String, dynamic>,
      });

      // Calculer la nouvelle date de fin d'abonnement
      DateTime maintenant = DateTime.now();
      DateTime nouvelleDateFin;

      if (prestataire.estPremium &&
          prestataire.finAbonnementPremium != null &&
          prestataire.finAbonnementPremium!.isAfter(maintenant)) {
        // Prolonger l'abonnement existant
        nouvelleDateFin = prestataire.finAbonnementPremium!.add(
          Duration(days: 30 * nombreMois),
        );
      } else {
        // Nouvel abonnement
        nouvelleDateFin = maintenant.add(Duration(days: 30 * nombreMois));
      }

      // Mettre à jour le prestataire
      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(prestataireId)
          .update({
            'estPremium': true,
            'finAbonnementPremium': nouvelleDateFin.millisecondsSinceEpoch,
          });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la souscription à l'abonnement premium: $e");
      }
      return false;
    }
  }
}
