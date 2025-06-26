import 'package:faso_services/services/base_donnees_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/utilisateur.dart';
import '../models/prestataire.dart';
import '../services/authentification_service.dart';
import '../services/stockage_service.dart';
import '../configs/constants.dart';

class ProfilViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthentificationService _authService = AuthentificationService();
  late StockageService _stockageService;

  Utilisateur? _utilisateur;
  Prestataire? _prestataire;
  List<String> _categoriesTemporaire = [];
  bool _estEnChargement = false;
  String? _erreur;

  // Getters
  Utilisateur? get utilisateur => _utilisateur;
  Prestataire? get prestataire => _prestataire;
  List<String> get categoriesTemporaire => _categoriesTemporaire;
  bool get estEnChargement => _estEnChargement;
  String? get erreur => _erreur;
  bool get estPrestataire => _utilisateur?.type == TypeUtilisateur.prestataire;

  ProfilViewModel(BaseDonneesService baseDonneesService) {
    _stockageService = StockageService();
    _initialiser();
  }
  void _initialiser() {
    _chargerUtilisateurActuel();
  }

  void toggleCategorie(String categorie) {
    if (_categoriesTemporaire.contains(categorie)) {
      _categoriesTemporaire.remove(categorie);
    } else {
      _categoriesTemporaire.add(categorie);
    }
    notifyListeners();
  }

  void _chargerUtilisateurActuel() {
    _authService.utilisateurActuel.listen((utilisateur) async {
      _utilisateur = utilisateur;

      if (_utilisateur != null &&
          _utilisateur!.type == TypeUtilisateur.prestataire) {
        await _chargerProfilPrestataire(_utilisateur!.id);
      }

      notifyListeners();
    });
  }

  Future<void> _chargerProfilPrestataire(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        _prestataire = Prestataire.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        _categoriesTemporaire = List<String>.from(
          _prestataire?.categories ?? [],
        );
      }
    } catch (e) {
      _erreur =
          "Erreur lors du chargement du profil prestataire: ${e.toString()}";
    }
  }

  Future<bool> mettreAJourProfil({
    String? nom,
    String? prenom,
    String? telephone,
    String? description,
    String? adresse,
    List<String>? categories,
    double? latitude,
    double? longitude,
  }) async {
    _setChargement(true);
    _erreur = null;

    try {
      Map<String, dynamic> donnees = {};

      if (nom != null) donnees['nom'] = nom;
      if (prenom != null) donnees['prenom'] = prenom;
      if (telephone != null) donnees['telephone'] = telephone;

      // Mettre à jour l'utilisateur de base
      await _firestore
          .collection(Constants.usersCollection)
          .doc(_utilisateur!.id)
          .update(donnees);

      // Si c'est un prestataire, mettre à jour les informations supplémentaires
      if (_utilisateur!.type == TypeUtilisateur.prestataire) {
        Map<String, dynamic> donneesPrestataire = {};

        if (description != null) {
          donneesPrestataire['description'] = description;
        }
        if (adresse != null) donneesPrestataire['adresse'] = adresse;
        if (categories != null) donneesPrestataire['categories'] = categories;
        if (latitude != null) donneesPrestataire['latitude'] = latitude;
        if (longitude != null) donneesPrestataire['longitude'] = longitude;

        if (donneesPrestataire.isNotEmpty) {
          await _firestore
              .collection(Constants.prestatairesCollection)
              .doc(_utilisateur!.id)
              .update(donneesPrestataire);
        }
      }

      // Recharger les données
      _chargerUtilisateurActuel();
      _setChargement(false);
      return true;
    } catch (e) {
      _setChargement(false);
      _erreur = "Erreur lors de la mise à jour du profil: ${e.toString()}";
      return false;
    }
  }

  Future<bool> changerPhotoProfil(File photo) async {
    _setChargement(true);
    _erreur = null;

    try {
      // Télécharger la nouvelle photo
      String chemin = 'profils/${_utilisateur!.id}';
      String? urlPhoto = await _stockageService.telechargerFichier(
        photo,
        chemin,
      );

      // Mettre à jour l'URL dans Firestore
      await _firestore
          .collection(Constants.usersCollection)
          .doc(_utilisateur!.id)
          .update({'photoProfil': urlPhoto});

      // Si prestataire, mettre à jour dans la collection prestataires aussi
      if (_utilisateur!.type == TypeUtilisateur.prestataire) {
        await _firestore
            .collection(Constants.prestatairesCollection)
            .doc(_utilisateur!.id)
            .update({'photoProfil': urlPhoto});
      }

      // Recharger les données
      _chargerUtilisateurActuel();
      _setChargement(false);
      return true;
    } catch (e) {
      _setChargement(false);
      _erreur = "Erreur lors du changement de photo de profil: ${e.toString()}";
      return false;
    }
  }

  Future<bool> ajouterPhotoPortfolio(File photo) async {
    if (_utilisateur?.type != TypeUtilisateur.prestataire) {
      _erreur =
          "Seuls les prestataires peuvent ajouter des photos au portfolio";
      return false;
    }

    _setChargement(true);
    _erreur = null;

    try {
      // Télécharger la nouvelle photo
      String chemin =
          'portfolios/${_utilisateur!.id}/${DateTime.now().millisecondsSinceEpoch}';
      String? urlPhoto = await _stockageService.telechargerFichier(
        photo,
        chemin,
      );

      // Récupérer le portfolio actuel
      List<String> photosActuelles = _prestataire?.photosPortfolio ?? [];
      photosActuelles.add(urlPhoto!);

      // Mettre à jour dans Firestore
      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(_utilisateur!.id)
          .update({'photosPortfolio': photosActuelles});

      // Recharger les données
      await _chargerProfilPrestataire(_utilisateur!.id);
      _setChargement(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setChargement(false);
      _erreur =
          "Erreur lors de l'ajout de la photo au portfolio: ${e.toString()}";
      return false;
    }
  }

  Future<bool> supprimerPhotoPortfolio(String urlPhoto) async {
    if (_utilisateur?.type != TypeUtilisateur.prestataire) {
      _erreur =
          "Seuls les prestataires peuvent supprimer des photos du portfolio";
      return false;
    }

    _setChargement(true);
    _erreur = null;

    try {
      // Récupérer le portfolio actuel et supprimer la photo
      List<String> photosActuelles = _prestataire?.photosPortfolio ?? [];
      photosActuelles.remove(urlPhoto);

      // Mettre à jour dans Firestore
      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(_utilisateur!.id)
          .update({'photosPortfolio': photosActuelles});

      // Supprimer le fichier du stockage
      await _stockageService.supprimerFichier(urlPhoto);

      // Recharger les données
      await _chargerProfilPrestataire(_utilisateur!.id);
      _setChargement(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setChargement(false);
      _erreur =
          "Erreur lors de la suppression de la photo du portfolio: ${e.toString()}";
      return false;
    }
  }

  Future<bool> changerMotDePasse(
    String ancienMotDePasse,
    String nouveauMotDePasse,
  ) async {
    _setChargement(true);
    _erreur = null;

    try {
      // Vérifier l'ancien mot de passe
      User? utilisateurFirebase = FirebaseAuth.instance.currentUser;

      if (utilisateurFirebase != null) {
        // Réauthentifier l'utilisateur
        AuthCredential credential = EmailAuthProvider.credential(
          email: utilisateurFirebase.email!,
          password: ancienMotDePasse,
        );

        await utilisateurFirebase.reauthenticateWithCredential(credential);

        // Changer le mot de passe
        await utilisateurFirebase.updatePassword(nouveauMotDePasse);

        _setChargement(false);
        return true;
      } else {
        _setChargement(false);
        _erreur = "Utilisateur non connecté";
        return false;
      }
    } catch (e) {
      _setChargement(false);

      if (e.toString().contains("wrong-password")) {
        _erreur = "L'ancien mot de passe est incorrect";
      } else {
        _erreur = "Erreur lors du changement de mot de passe: ${e.toString()}";
      }

      return false;
    }
  }

  void _setChargement(bool enChargement) {
    _estEnChargement = enChargement;
    notifyListeners();
  }

  Future<void> mettreAJourProfilClient({
    required String nom,
    required String prenom,
    required String telephone,
    String? photoProfil,
  }) async {
    await mettreAJourProfil(nom: nom, prenom: prenom, telephone: telephone);

    // Si une nouvelle photo est fournie, la mettre à jour
    if (photoProfil != null) {
      await _firestore
          .collection(Constants.usersCollection)
          .doc(_utilisateur!.id)
          .update({'photoProfil': photoProfil});
    }
  }

  Future<void> mettreAJourProfilPrestataire({
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
    required String description,
    String? photoProfil,
  }) async {
    await mettreAJourProfil(
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      adresse: adresse,
      description: description,
      categories: _categoriesTemporaire,
    );

    // Si une nouvelle photo est fournie, la mettre à jour
    if (photoProfil != null) {
      await _firestore
          .collection(Constants.usersCollection)
          .doc(_utilisateur!.id)
          .update({'photoProfil': photoProfil});

      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(_utilisateur!.id)
          .update({'photoProfil': photoProfil});
    }
  }
}
