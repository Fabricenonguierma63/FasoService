import 'package:faso_services/services/base_donnees_service.dart';
import 'package:faso_services/services/localisation_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';
import '../models/prestataire.dart';
import '../services/authentification_service.dart';
import '../models/utilisateur.dart';
import '../configs/constants.dart';

class AccueilViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthentificationService _authService = AuthentificationService();

  List<Service> _servicesPopulaires = [];
  List<Prestataire> _prestatairesRecommandes = [];
  final List<String> _categories = Constants.categories;
  bool _estEnChargement = false;
  String? _erreur;
  Utilisateur? _utilisateurActuel;

  // Getters
  List<Service> get servicesPopulaires => _servicesPopulaires;
  List<Prestataire> get prestatairesRecommandes => _prestatairesRecommandes;
  List<String> get categories => _categories;
  bool get estEnChargement => _estEnChargement;
  String? get erreur => _erreur;
  Utilisateur? get utilisateurActuel => _utilisateurActuel;
  bool get isLoading => _estEnChargement;

  AccueilViewModel(
    BaseDonneesService baseDonneesService,
    LocalisationService localisationService,
  ) {
    _initialiser();
  }

  get prestataires => null;

  void _initialiser() {
    _chargerUtilisateurActuel();
    chargerServicesPopulaires();
    chargerPrestatairesRecommandes();
  }

  void _chargerUtilisateurActuel() {
    _authService.utilisateurActuel.listen((utilisateur) {
      _utilisateurActuel = utilisateur;
      notifyListeners();
    });
  }

  Future<void> chargerServicesPopulaires() async {
    _setChargement(true);

    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(Constants.servicesCollection)
              .where('estDisponible', isEqualTo: true)
              .orderBy('dateCreation', descending: true)
              .limit(10)
              .get();

      _servicesPopulaires =
          snapshot.docs
              .map(
                (doc) => Service.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList();

      _setChargement(false);
    } catch (e) {
      _setChargement(false);
      _erreur =
          "Erreur lors du chargement des services populaires: ${e.toString()}";
    }
  }

  Future<void> chargerPrestatairesRecommandes() async {
    _setChargement(true);

    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(Constants.prestatairesCollection)
              .where('estDisponible', isEqualTo: true)
              .orderBy('noteMoyenne', descending: true)
              .limit(5)
              .get();

      _prestatairesRecommandes =
          snapshot.docs
              .map(
                (doc) => Prestataire.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList();

      _setChargement(false);
    } catch (e) {
      _setChargement(false);
      _erreur =
          "Erreur lors du chargement des prestataires recommandés: ${e.toString()}";
    }
  }

  Future<List<Service>> chargerServicesParCategorie(String categorie) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(Constants.servicesCollection)
              .where('categorie', isEqualTo: categorie)
              .where('estDisponible', isEqualTo: true)
              .limit(20)
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
      _erreur =
          "Erreur lors du chargement des services par catégorie: ${e.toString()}";
      return [];
    }
  }

  void _setChargement(bool enChargement) {
    _estEnChargement = enChargement;
    notifyListeners();
  }

  void rafraichirDonnees() {
    chargerServicesPopulaires();
    chargerPrestatairesRecommandes();
  }
}
