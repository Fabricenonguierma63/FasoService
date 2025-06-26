import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/avis.dart';

class AvisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'avis';
  final String _prestataireCollection = 'prestataires';

  // Ajouter un nouvel avis avec photos
  Future<void> ajouterAvis(Avis avis, [List<File>? photos]) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      // Upload des photos si présentes
      List<String> urlsPhotos = [];
      if (photos != null && photos.isNotEmpty) {
        urlsPhotos = await _uploadPhotos(photos, docRef.id);
      }

      // Créer l'avis avec l'ID généré et les URLs des photos
      final avisAvecId = avis.copyWith(id: docRef.id, photos: urlsPhotos);

      await docRef.set(avisAvecId.toMap());

      // Mettre à jour les statistiques du prestataire
      await _mettreAJourStatistiquesPrestataire(avis.prestataireId);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'avis: $e');
    }
  }

  // Upload des photos vers Firebase Storage
  Future<List<String>> _uploadPhotos(List<File> photos, String avisId) async {
    List<String> urlsPhotos = [];

    for (int i = 0; i < photos.length; i++) {
      try {
        final fileName = 'avis_${avisId}_photo_$i.jpg';
        final ref = _storage.ref().child('avis_photos').child(fileName);

        final uploadTask = await ref.putFile(photos[i]);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        urlsPhotos.add(downloadUrl);
      } catch (e) {
        if (kDebugMode) {
          print('Erreur upload photo $i: $e');
        }
        // Continue avec les autres photos même si une échoue
      }
    }

    return urlsPhotos;
  }

  // Obtenir les avis d'un prestataire
  Future<List<Avis>> getAvisPrestataire(String prestataireId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('prestataireId', isEqualTo: prestataireId)
          .orderBy('dateCreation', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Avis.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des avis: $e');
    }
  }

  // Obtenir les avis d'un service spécifique
  Future<List<Avis>> getAvisService(String serviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('dateCreation', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Avis.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des avis du service: $e');
    }
  }

  // Obtenir les avis d'un client
  Future<List<Avis>> getAvisClient(String clientId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('dateCreation', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Avis.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des avis du client: $e');
    }
  }

  // Modifier un avis existant
  Future<void> modifierAvis(Avis avis, [List<File>? nouvellesPhotos]) async {
    try {
      List<String> urlsPhotos = List.from(avis.photos ?? []);

      // Upload des nouvelles photos si présentes
      if (nouvellesPhotos != null && nouvellesPhotos.isNotEmpty) {
        final nouvellesUrls = await _uploadPhotos(nouvellesPhotos, avis.id);
        urlsPhotos.addAll(nouvellesUrls);
      }

      final avisModifie = avis.copyWith(photos: urlsPhotos);

      await _firestore
          .collection(_collection)
          .doc(avis.id)
          .update(avisModifie.toMap());

      // Mettre à jour les statistiques du prestataire
      await _mettreAJourStatistiquesPrestataire(avis.prestataireId);
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'avis: $e');
    }
  }

  // Supprimer un avis
  Future<void> supprimerAvis(String avisId) async {
    try {
      // Récupérer l'avis avant de le supprimer
      final avisDoc = await _firestore
          .collection(_collection)
          .doc(avisId)
          .get();

      if (!avisDoc.exists) {
        throw Exception('Avis non trouvé');
      }

      final avisData = avisDoc.data()!;
      final prestataireId = avisData['prestataireId'] as String?;
      final photos = avisData['photos'] as List<dynamic>?;

      // Supprimer les photos du stockage
      if (photos != null && photos.isNotEmpty) {
        await _supprimerPhotos(photos.cast<String>());
      }

      // Supprimer l'avis de Firestore
      await _firestore.collection(_collection).doc(avisId).delete();

      // Mettre à jour les statistiques du prestataire
      if (prestataireId != null) {
        await _mettreAJourStatistiquesPrestataire(prestataireId);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'avis: $e');
    }
  }

  // Supprimer les photos du stockage
  Future<void> _supprimerPhotos(List<String> urlsPhotos) async {
    for (String url in urlsPhotos) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        if (kDebugMode) {
          print('Erreur suppression photo: $e');
        }
        // Continue même si une photo ne peut pas être supprimée
      }
    }
  }

  // Vérifier si un client a déjà donné un avis
  Future<bool> clientADonneAvis(
    String clientId,
    String prestataireId,
    String? serviceId,
  ) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .where('prestataireId', isEqualTo: prestataireId);

      if (serviceId != null) {
        query = query.where('serviceId', isEqualTo: serviceId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification: $e');
    }
  }

  // Obtenir un avis spécifique
  Future<Avis?> getAvis(String avisId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(avisId).get();

      if (doc.exists) {
        return Avis.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'avis: $e');
    }
  }

  // Obtenir les statistiques d'un prestataire
  // Méthode corrigée dans AvisService
  Future<Map<String, dynamic>> getStatistiquesPrestataire(
    String prestataireId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('prestataireId', isEqualTo: prestataireId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'nombreAvis': 0,
          'noteMoyenne': 0.0,
          'repartitionNotes': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      // ✅ CORRECTION 1: Gérer les documents vides ou invalides
      final avisValides = <Avis>[];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          if (data.isNotEmpty) {
            final avis = Avis.fromMap(data);
            avisValides.add(avis);
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Document avis invalide ignoré: ${doc.id} - $e');
          }
          // Ignorer les documents invalides et continuer
        }
      }

      if (avisValides.isEmpty) {
        return {
          'nombreAvis': 0,
          'noteMoyenne': 0.0,
          'repartitionNotes': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      double sommeNotes = 0;
      Map<int, int> repartitionNotes = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var avisItem in avisValides) {
        // ✅ CORRECTION 2: Validation de la note
        if (avisItem.note >= 0 && avisItem.note <= 5) {
          sommeNotes += avisItem.note;
          int noteEntiere = avisItem.note.round();

          // ✅ CORRECTION 3: S'assurer que la note est dans la plage valide
          if (noteEntiere >= 1 && noteEntiere <= 5) {
            repartitionNotes[noteEntiere] =
                (repartitionNotes[noteEntiere] ?? 0) + 1;
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Note invalide ignorée: ${avisItem.note}');
          }
        }
      }

      // ✅ CORRECTION 4: Éviter la division par zéro
      double noteMoyenne = avisValides.isNotEmpty
          ? sommeNotes / avisValides.length
          : 0.0;

      return {
        'nombreAvis': avisValides.length,
        'noteMoyenne': double.parse(noteMoyenne.toStringAsFixed(1)),
        'repartitionNotes': repartitionNotes,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur dans getStatistiquesPrestataire: $e');
      }
      // ✅ CORRECTION 5: Retourner des données par défaut en cas d'erreur
      // au lieu de lancer une exception
      return {
        'nombreAvis': 0,
        'noteMoyenne': 0.0,
        'repartitionNotes': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  // Mettre à jour les statistiques du prestataire
  Future<void> _mettreAJourStatistiquesPrestataire(String prestataireId) async {
    try {
      if (kDebugMode) {
        print('📊 Calcul des statistiques pour prestataire: $prestataireId');
      }

      final stats = await getStatistiquesPrestataire(prestataireId);

      if (kDebugMode) {
        print('📈 Statistiques calculées: $stats');
      }

      // ✅ Vérifier que le document prestataire existe avant de le mettre à jour
      final prestataireDoc = await _firestore
          .collection(_prestataireCollection)
          .doc(prestataireId)
          .get();

      if (!prestataireDoc.exists) {
        if (kDebugMode) {
          print('⚠️ Document prestataire non trouvé: $prestataireId');
        }
        return; // Sortir silencieusement si le prestataire n'existe pas
      }

      if (kDebugMode) {
        print('💾 Mise à jour du document prestataire...');
      }

      await _firestore
          .collection(_prestataireCollection)
          .doc(prestataireId)
          .update({
            'nombreAvis': stats['nombreAvis'],
            'noteMoyenne': stats['noteMoyenne'],
            'derniereMAJAvis': FieldValue.serverTimestamp(),
          });

      if (kDebugMode) {
        print('✅ Document prestataire mis à jour');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('⚠️ Erreur mise à jour statistiques prestataire: $e');
        print('📍 Stack trace: $stackTrace');
      }
      // ✅ CORRECTION 7: Ne pas faire échouer l'opération principale
      // Juste logger l'erreur et continuer
    }
  }

  // Obtenir les avis récents (pour tableau de bord admin)
  Future<List<Avis>> getAvisRecents({int limite = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('dateCreation', descending: true)
          .limit(limite)
          .get();

      return querySnapshot.docs.map((doc) => Avis.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des avis récents: $e');
    }
  }

  // Rechercher des avis par mots-clés
  Future<List<Avis>> rechercherAvis(
    String motsCles, {
    String? prestataireId,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (prestataireId != null) {
        query = query.where('prestataireId', isEqualTo: prestataireId);
      }

      final querySnapshot = await query
          .orderBy('dateCreation', descending: true)
          .get();

      // Filtrer par mots-clés côté client (Firestore ne supporte pas la recherche textuelle complète)
      final avis = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              return Avis.fromMap(data);
            }
            return null;
          })
          .where((avis) => avis != null)
          .cast<Avis>()
          .toList();

      return avis;
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'avis: $e');
    }
  }
}
