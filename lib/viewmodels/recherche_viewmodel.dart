import 'package:faso_services/services/base_donnees_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/prestataire.dart';
import '../models/service.dart';
import '../services/localisation_service.dart';
import '../configs/constants.dart';

class RechercheViewModel extends ChangeNotifier {
  final BaseDonneesService _baseDonneesService;
  final LocalisationService _localisationService;

  List<Prestataire> _prestataires = [];
  List<Service> _services = [];
  String _categorieSelectionnee = '';
  String _termeRecherche = '';
  bool _rechercheParProximite = false;
  double _rayonRecherche = 10.0; // Rayon de recherche en km
  bool _estChargement = false;
  String? _erreur;
  Position? _positionActuelle;

  RechercheViewModel(this._baseDonneesService, this._localisationService);

  // Getters
  List<Prestataire> get prestataires => _prestataires;
  List<Service> get services => _services;
  String get categorieSelectionnee => _categorieSelectionnee;
  String get termeRecherche => _termeRecherche;
  bool get rechercheParProximite => _rechercheParProximite;
  double get rayonRecherche => _rayonRecherche;
  bool get estChargement => _estChargement;
  String? get erreur => _erreur;
  Position? get positionActuelle => _positionActuelle;
  List<String> get categories => Constants.categories;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> rechercherPrestataires(String motCle, String categorie) async {
    setLoading(true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('prestataires').get();

      _prestataires =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return Prestataire.fromMap(data);
              })
              .where((p) {
                final correspondCat =
                    categorie == "Tous" || p.categories.contains(categorie);
                final correspondTexte =
                    motCle.isEmpty ||
                    p.nom.toLowerCase().contains(motCle.toLowerCase()) ||
                    p.prenom.toLowerCase().contains(motCle.toLowerCase()) ||
                    p.description.toLowerCase().contains(motCle.toLowerCase());

                return correspondCat && correspondTexte;
              })
              .toList();
    } catch (e) {
      if (kDebugMode) {
        print("Erreur recherche : $e");
      }
    }
    setLoading(false);
  }

  // Initialisation
  Future<void> initialiser() async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      // Obtenir la position actuelle
      _positionActuelle = await _localisationService.obtenirPositionActuelle();
      await chargerPrestataires();
    } catch (e) {
      _erreur = 'Erreur lors de l\'initialisation: $e';
      if (kDebugMode) {
        print(_erreur);
      }
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Définir la catégorie sélectionnée
  void selectionnerCategorie(String categorie) {
    _categorieSelectionnee = categorie;
    filtrerResultats();
    notifyListeners();
  }

  // Définir le terme de recherche
  void definirTermeRecherche(String terme) {
    _termeRecherche = terme;
    filtrerResultats();
    notifyListeners();
  }

  // Activer/désactiver la recherche par proximité
  void basculerRechercheParProximite(bool valeur) async {
    _rechercheParProximite = valeur;

    if (valeur && _positionActuelle == null) {
      try {
        _positionActuelle =
            await _localisationService.obtenirPositionActuelle();
      } catch (e) {
        _erreur = 'Impossible d\'obtenir votre position: $e';
        _rechercheParProximite = false;
      }
    }

    filtrerResultats();
    notifyListeners();
  }

  // Définir le rayon de recherche
  void definirRayonRecherche(double rayon) {
    _rayonRecherche = rayon;
    filtrerResultats();
    notifyListeners();
  }

  // Charger les prestataires depuis Firestore
  Future<void> chargerPrestataires() async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      final QuerySnapshot prestataireSnapshot =
          await _baseDonneesService.firestore
              .collection(Constants.prestatairesCollection)
              .get();

      _prestataires =
          prestataireSnapshot.docs
              .map(
                (doc) => Prestataire.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList();

      await chargerServices();
      filtrerResultats();
    } catch (e) {
      _erreur = 'Erreur lors du chargement des prestataires: $e';
      if (kDebugMode) {
        print(_erreur);
      }
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Charger les services depuis Firestore
  Future<void> chargerServices() async {
    try {
      final QuerySnapshot serviceSnapshot =
          await _baseDonneesService.firestore
              .collection(Constants.servicesCollection)
              .where('estDisponible', isEqualTo: true)
              .get();

      _services =
          serviceSnapshot.docs
              .map(
                (doc) => Service.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList();
    } catch (e) {
      _erreur = 'Erreur lors du chargement des services: $e';
      if (kDebugMode) {
        print(_erreur);
      }
    }
  }

  // Obtenir les services d'un prestataire
  List<Service> obtenirServicesPrestataire(String prestataireId) {
    return _services
        .where((service) => service.prestataireId == prestataireId)
        .toList();
  }

  // Filtrer les résultats selon les critères de recherche
  void filtrerResultats() {
    List<Prestataire> resultats = List.from(_prestataires);

    // Filtrer par catégorie
    if (_categorieSelectionnee.isNotEmpty) {
      resultats =
          resultats
              .where(
                (prestataire) =>
                    prestataire.categories.contains(_categorieSelectionnee),
              )
              .toList();
    }

    // Filtrer par terme de recherche
    if (_termeRecherche.isNotEmpty) {
      final termeLower = _termeRecherche.toLowerCase();
      resultats =
          resultats.where((prestataire) {
            return prestataire.nom.toLowerCase().contains(termeLower) ||
                prestataire.prenom.toLowerCase().contains(termeLower) ||
                prestataire.description.toLowerCase().contains(termeLower) ||
                prestataire.adresse.toLowerCase().contains(termeLower);
          }).toList();
    }

    // Filtrer par proximité
    if (_rechercheParProximite && _positionActuelle != null) {
      resultats =
          resultats.where((prestataire) {
            final distance = prestataire.calculerDistance(
              _positionActuelle!.latitude,
              _positionActuelle!.longitude,
            );
            return distance <= _rayonRecherche;
          }).toList();

      // Trier par distance
      resultats.sort((a, b) {
        final distanceA = a.calculerDistance(
          _positionActuelle!.latitude,
          _positionActuelle!.longitude,
        );
        final distanceB = b.calculerDistance(
          _positionActuelle!.latitude,
          _positionActuelle!.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
    } else {
      // Trier par note moyenne (meilleure note en premier)
      resultats.sort((a, b) => b.noteMoyenne.compareTo(a.noteMoyenne));
    }

    _prestataires = resultats;
    notifyListeners();
  }

  // Recherche avancée avec plusieurs critères
  Future<void> rechercheAvancee({
    String? categorie,
    String? terme,
    bool? parProximite,
    double? rayon,
    bool? disponibleSeulement,
    bool? verifieSeulement,
  }) async {
    if (categorie != null) _categorieSelectionnee = categorie;
    if (terme != null) _termeRecherche = terme;
    if (parProximite != null) basculerRechercheParProximite(parProximite);
    if (rayon != null) _rayonRecherche = rayon;

    List<Prestataire> resultats = List.from(_prestataires);

    if (disponibleSeulement == true) {
      resultats = resultats.where((p) => p.estDisponible).toList();
    }

    if (verifieSeulement == true) {
      resultats =
          resultats.where((p) => p.estVerifieProfessionnellement).toList();
    }

    _prestataires = resultats;
    filtrerResultats();
  }

  // Réinitialiser les filtres
  void reinitialiserFiltres() {
    _categorieSelectionnee = '';
    _termeRecherche = '';
    _rechercheParProximite = false;
    _rayonRecherche = 10.0;
    chargerPrestataires();
  }
}
