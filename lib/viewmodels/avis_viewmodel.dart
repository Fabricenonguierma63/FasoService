import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../models/avis.dart';
import '../services/avis_service.dart';

class AvisViewModel extends ChangeNotifier {
  final AvisService _avisService = AvisService();
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  
  // État de chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Liste des avis
  List<Avis> _avis = [];
  List<Avis> get avis => _avis;

  // Statistiques
  Map<String, dynamic> _statistiques = {};
  Map<String, dynamic> get statistiques => _statistiques;

  // Messages d'erreur
  String? _erreur;
  String? get erreur => _erreur;
  String get messageErreur => _erreur ?? '';

  // Avis sélectionné
  Avis? _avisSelectionne;
  Avis? get avisSelectionne => _avisSelectionne;

  // Setter pour l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Setter pour les erreurs
  void _setErreur(String? erreur) {
    _erreur = erreur;
    notifyListeners();
  }

  // Effacer les erreurs
  void effacerErreur() {
    _erreur = null;
    notifyListeners();
  }

  // ← NOUVELLE MÉTHODE : Récupérer l'ID de l'utilisateur connecté
  String? _getCurrentUserId() {
    final User? user = _auth.currentUser;
    return user?.uid;
  }

  Future<bool> creerAvis({
    required String prestataireId,
    required String serviceId,
    required String reservationId,
    required int note,
    required String commentaire,
    List<File>? photos,
  }) async {
    try {
      if (kDebugMode) {
        print(' DÉBUT creerAvis()');
        print(' Paramètres reçus:');
        print('  - prestataireId: $prestataireId');
        print('  - serviceId: $serviceId');
        print('  - note: $note');
        print('  - commentaire: $commentaire');
      }

      _setLoading(true);
      _setErreur(null);

      //  CORRECTION 1: Validation des paramètres
      if (prestataireId.isEmpty ||
          serviceId.isEmpty ||
          commentaire.trim().isEmpty) {
        _setErreur('Paramètres manquants');
        _setLoading(false);
        return false;
      }

      if (note < 1 || note > 5) {
        _setErreur('Note invalide (doit être entre 1 et 5)');
        _setLoading(false);
        return false;
      }

      // Récupérer l'ID de l'utilisateur connecté
      final String? currentUserId = _getCurrentUserId();

      if (currentUserId == null) {
        if (kDebugMode) {
          print('❌ Utilisateur non connecté');
        }
        _setErreur('Utilisateur non connecté');
        _setLoading(false);
        return false;
      }

      if (kDebugMode) {
        print('👤 User ID: $currentUserId');
      }

      //  CORRECTION 2: Vérification d'avis existant avec timeout
      try {
        if (kDebugMode) {
          print('🔍 Vérification avis existant...');
        }

        final avisExiste = await _avisService
            .clientADonneAvis(currentUserId, prestataireId, serviceId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                if (kDebugMode) {
                  print('⏰ Timeout lors de la vérification d\'avis existant');
                }
                return false; // En cas de timeout, on assume qu'il n'y a pas d'avis
              },
            );

        if (kDebugMode) {
          print('📊 Avis existe déjà: $avisExiste');
        }

        if (avisExiste) {
          if (kDebugMode) {
            print('⚠️ L\'utilisateur a déjà donné un avis');
          }
          _setErreur('Vous avez déjà donné un avis pour ce service');
          _setLoading(false);
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erreur lors de la vérification d\'avis existant: $e');
        }
        // Continuer même si la vérification échoue
      }

      //  CORRECTION 3: Créer l'objet Avis avec validation
      final avis = Avis(
        id: '', // Sera généré par Firestore
        clientId: currentUserId,
        prestataireId: prestataireId,
        serviceId: serviceId,
        note: note.toDouble(),
        commentaire: commentaire.trim(),
        dateCreation: DateTime.now(),
        photos: [], // Sera rempli par le service
      );

      if (kDebugMode) {
        print('📝 Avis créé: ${avis.toMap()}');
      }

      //  CORRECTION 4: Ajout avec timeout et gestion d'erreur
      try {
        if (kDebugMode) {
          print('📡 Appel ajouterAvis...');
        }

        await _avisService
            .ajouterAvis(avis, photos)
            .timeout(
              const Duration(seconds: 30), // Timeout plus long pour l'upload
              onTimeout: () {
                throw Exception('Timeout lors de l\'ajout de l\'avis');
              },
            );

        if (kDebugMode) {
          print('✅ Avis ajouté avec succès');
        }

        //  CORRECTION 5: Recharger les données (optionnel, avec gestion d'erreur)
        try {
          await chargerAvisPrestataire(prestataireId);
        } catch (e) {
          if (kDebugMode) {
            print(' Erreur lors du rechargement des avis: $e');
          }
          // Ne pas faire échouer l'opération principale
        }

        _setLoading(false);
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('💥 Erreur lors de l\'ajout de l\'avis: $e');
        }

        //  Messages d'erreur plus spécifiques
        String messageErreur = 'Erreur lors de l\'ajout de l\'avis';
        if (e.toString().contains('permission')) {
          messageErreur = 'Vous n\'avez pas les permissions nécessaires';
        } else if (e.toString().contains('network')) {
          messageErreur = 'Problème de connexion réseau';
        } else if (e.toString().contains('timeout')) {
          messageErreur = 'L\'opération a pris trop de temps';
        }

        _setErreur(messageErreur);
        _setLoading(false);
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('💥 ERREUR GÉNÉRALE dans creerAvis: $e');
        print('📍 Stack trace: $stackTrace');
      }
      _setErreur('Erreur inattendue: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Méthode ajouterAvis améliorée
  Future<bool> ajouterAvis(Avis avis, [List<File>? photos]) async {
    try {
      if (kDebugMode) {
        print('🔄 DÉBUT ajouterAvis()');
      }
      if (kDebugMode) {
        print('📋 Avis à ajouter: ${avis.toMap()}');
      }

      _setLoading(true);
      _setErreur(null);

      if (kDebugMode) {
        print('📡 Appel _avisService.ajouterAvis...');
      }
      await _avisService.ajouterAvis(avis, photos);
      if (kDebugMode) {
        print('✅ _avisService.ajouterAvis terminé avec succès');
      }

      if (kDebugMode) {
        print('🔄 Rechargement des avis du prestataire...');
      }
      await chargerAvisPrestataire(avis.prestataireId);
      if (kDebugMode) {
        print('✅ Avis du prestataire rechargés');
      }

      _setLoading(false);
      if (kDebugMode) {
        print('🎉 ajouterAvis terminé avec succès');
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('💥 ERREUR dans ajouterAvis: $e');
      }
      if (kDebugMode) {
        print('📍 Stack trace: $stackTrace');
      }
      _setErreur('Erreur lors de l\'ajout de l\'avis: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Charger les avis d'un prestataire
  Future<void> chargerAvisPrestataire(String prestataireId) async {
    try {
      _setLoading(true);
      _setErreur(null);

      _avis = await _avisService.getAvisPrestataire(prestataireId);

      // Charger aussi les statistiques
      await chargerStatistiquesPrestataire(prestataireId);

      _setLoading(false);
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
    }
  }

  // Vérifier si un client a déjà donné un avis
  Future<bool> verifierAvisExistant(
    String prestataireId,
    String? serviceId,
  ) async {
    try {
      final String? clientId = _getCurrentUserId();

      if (clientId == null) {
        _setErreur('Utilisateur non connecté');
        return false;
      }

      // ✅ Ajout d'un timeout
      return await _avisService
          .clientADonneAvis(clientId, prestataireId, serviceId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              if (kDebugMode) {
                print('⏰ Timeout lors de la vérification d\'avis existant');
              }
              return false; // En cas de timeout, on assume qu'il n'y a pas d'avis
            },
          );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur dans verifierAvisExistant: $e');
      }
      // Ne pas définir d'erreur ici car c'est juste une vérification
      return false; // En cas d'erreur, on assume qu'il n'y a pas d'avis
    }
  }

  // Charger les avis d'un client (utilisateur connecté)
  Future<void> chargerMesAvis() async {
    try {
      _setLoading(true);
      _setErreur(null);

      final String? clientId = _getCurrentUserId();

      if (clientId == null) {
        _setErreur('Utilisateur non connecté');
        _setLoading(false);
        return;
      }

      _avis = await _avisService.getAvisClient(clientId);

      _setLoading(false);
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
    }
  }

  // Charger les avis d'un service
  Future<void> chargerAvisService(String serviceId) async {
    try {
      _setLoading(true);
      _setErreur(null);

      _avis = await _avisService.getAvisService(serviceId);

      _setLoading(false);
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
    }
  }

  // Charger les avis d'un client
  Future<void> chargerAvisClient(String clientId) async {
    try {
      _setLoading(true);
      _setErreur(null);

      _avis = await _avisService.getAvisClient(clientId);

      _setLoading(false);
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
    }
  }

  // Charger les statistiques d'un prestataire
  Future<void> chargerStatistiquesPrestataire(String prestataireId) async {
    try {
      _statistiques = await _avisService.getStatistiquesPrestataire(
        prestataireId,
      );
      notifyListeners();
    } catch (e) {
      _setErreur(e.toString());
    }
  }

  // Modifier un avis
  Future<bool> modifierAvis(Avis avis, [List<File>? nouvellesPhotos]) async {
    try {
      _setLoading(true);
      _setErreur(null);

      await _avisService.modifierAvis(avis, nouvellesPhotos);

      // Recharger la liste des avis
      await chargerAvisPrestataire(avis.prestataireId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Supprimer un avis
  Future<bool> supprimerAvis(String avisId, String prestataireId) async {
    try {
      _setLoading(true);
      _setErreur(null);

      await _avisService.supprimerAvis(avisId);

      // Recharger la liste des avis
      await chargerAvisPrestataire(prestataireId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Obtenir un avis spécifique
  Future<void> chargerAvis(String avisId) async {
    try {
      _setLoading(true);
      _setErreur(null);

      _avisSelectionne = await _avisService.getAvis(avisId);

      _setLoading(false);
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
    }
  }

  // Charger les avis récents
  Future<void> chargerAvisRecents({int limite = 10}) async {
    try {
      _setLoading(true);
      _setErreur(null);

      _avis = await _avisService.getAvisRecents(limite: limite);

      _setLoading(false);
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
    }
  }

  // Rechercher des avis
  Future<void> rechercherAvis(String motsCles, {String? prestataireId}) async {
    try {
      _setLoading(true);
      _setErreur(null);

      _avis = await _avisService.rechercherAvis(
        motsCles,
        prestataireId: prestataireId,
      );

      _setLoading(false);
    } catch (e) {
      _setErreur(e.toString());
      _setLoading(false);
    }
  }

  // Obtenir la note moyenne
  double get noteMoyenne {
    if (_statistiques.containsKey('noteMoyenne')) {
      return _statistiques['noteMoyenne'].toDouble();
    }
    return 0.0;
  }

  // Obtenir le nombre total d'avis
  int get nombreTotalAvis {
    if (_statistiques.containsKey('nombreAvis')) {
      return _statistiques['nombreAvis'];
    }
    return 0;
  }

  // Obtenir la répartition des notes
  Map<int, int> get repartitionNotes {
    if (_statistiques.containsKey('repartitionNotes')) {
      return Map<int, int>.from(_statistiques['repartitionNotes']);
    }
    return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  }

  // Filtrer les avis par note
  List<Avis> filtrerParNote(double noteMin, double noteMax) {
    return _avis
        .where((avis) => avis.note >= noteMin && avis.note <= noteMax)
        .toList();
  }

  // Filtrer les avis avec photos
  List<Avis> get avisAvecPhotos {
    return _avis
        .where((avis) => avis.photos != null && avis.photos!.isNotEmpty)
        .toList();
  }

  // Obtenir les avis les plus récents
  List<Avis> get avisPlusRecents {
    final avisTriees = List<Avis>.from(_avis);
    avisTriees.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return avisTriees;
  }

  // Obtenir les avis les mieux notés
  List<Avis> get avisMieuxNotes {
    final avisTriees = List<Avis>.from(_avis);
    avisTriees.sort((a, b) => b.note.compareTo(a.note));
    return avisTriees;
  }

  // Réinitialiser les données
  void reinitialiser() {
    _avis.clear();
    _statistiques.clear();
    _avisSelectionne = null;
    _erreur = null;
    _isLoading = false;
    notifyListeners();
  }

  // Obtenir le pourcentage pour une note donnée
  double getPourcentageNote(int note) {
    if (nombreTotalAvis == 0) return 0.0;

    final nombrePourNote = repartitionNotes[note] ?? 0;
    return (nombrePourNote / nombreTotalAvis) * 100;
  }

  // Vérifier si il y a des avis
  bool get aDesAvis => _avis.isNotEmpty;

  // Obtenir le texte de la note moyenne
  String get texteNoteMoyenne {
    final moyenne = noteMoyenne;
    if (moyenne <= 1) return "Très insatisfaisant";
    if (moyenne <= 2) return "Insatisfaisant";
    if (moyenne <= 3) return "Moyen";
    if (moyenne <= 4) return "Satisfaisant";
    return "Très satisfaisant";
  }

  // ← NOUVELLE MÉTHODE : Vérifier si l'utilisateur est connecté
  bool get estConnecte => _auth.currentUser != null;

  // ← NOUVELLE MÉTHODE : Récupérer l'ID de l'utilisateur connecté (public)
  String? get utilisateurConnecteId => _getCurrentUserId();
}
