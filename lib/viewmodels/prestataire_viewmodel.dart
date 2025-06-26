import 'dart:io';
import 'package:faso_services/services/base_donnees_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prestataire.dart';
import '../models/service.dart';
import '../models/avis.dart';
//import '../models/reservation.dart';
import '../configs/constants.dart';
import '../services/stockage_service.dart';
import '../services/whatsapp_service.dart';

class PrestataireViewModel extends ChangeNotifier {
  final BaseDonneesService _baseDonneesService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StockageService _stockageService = StockageService();
  final WhatsappService _whatsappService = WhatsappService();

  Prestataire? _prestataire;
  List<Service> _services = [];
  List<Avis> _avis = [];
  double _noteMoyenne = 0.0;
  bool _estChargement = false;
  String? _erreur;

  PrestataireViewModel(this._baseDonneesService);

  // Getters
  Prestataire? get prestataire => _prestataire;
  List<Service> get services => _services;
  List<Avis> get avis => _avis;
  List<String> get toutesCategories => Constants.categories;
  double get noteMoyenne => _noteMoyenne;
  bool get estChargement => _estChargement;
  String? get erreur => _erreur;

  get mesServices => _services;

  // Charger les détails d'un prestataire par son ID
  Future<void> chargerPrestataire(String prestataireId) async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      final DocumentSnapshot docSnapshot = await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(prestataireId)
          .get();

      if (docSnapshot.exists) {
        _prestataire = Prestataire.fromMap({
          'id': docSnapshot.id,
          ...docSnapshot.data() as Map<String, dynamic>,
        });

        await Future.wait([
          chargerServices(prestataireId),
          chargerAvis(prestataireId),
        ]);

        _calculerNoteMoyenne();
      } else {
        _erreur = 'Prestataire non trouvé';
      }
    } catch (e) {
      _erreur = 'Erreur lors du chargement du prestataire: $e';
      if (kDebugMode) {
        print(_erreur);
      }
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Charger les services offerts par le prestataire
  Future<void> chargerServices([String? prestataireId]) async {
    final id = prestataireId ?? _prestataire?.id;
    if (id == null) return;

    try {
      final QuerySnapshot servicesSnapshot = await _firestore
          .collection(Constants.servicesCollection)
          .where(
            'prestataireId',
            isEqualTo: id,
          ) // ← Utiliser 'id' au lieu de 'prestataireId'
          .where(
            'estDisponible',
            isEqualTo: true,
          ) // ← Requête simple et correcte
          .get();
      _services = servicesSnapshot.docs
          .map(
            (doc) => Service.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      // Trier par date de création (plus récent en premier)
      _services.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des services: $e');
      }
    }
  }

  // Charger les avis pour le prestataire
  Future<void> chargerAvis(String prestataireId) async {
    try {
      final QuerySnapshot avisSnapshot = await _firestore
          .collection(Constants.avisCollection)
          .where('prestataireId', isEqualTo: prestataireId)
          .orderBy('dateCreation', descending: true)
          .get();

      _avis = avisSnapshot.docs
          .map(
            (doc) => Avis.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des avis: $e');
      }
    }
  }

  // Calculer la note moyenne à partir des avis
  void _calculerNoteMoyenne() {
    if (_avis.isEmpty) {
      _noteMoyenne = 0.0;
      return;
    }

    double somme = 0;
    for (var avis in _avis) {
      somme += avis.note;
    }

    _noteMoyenne = somme / _avis.length;
  }

  // Contacter le prestataire via WhatsApp
  Future<bool> contacterViaWhatsApp() async {
    if (_prestataire == null) return false;

    try {
      final resultat = await _whatsappService.ouvrirWhatsApp(
        _prestataire!.telephone,
        "Bonjour, je vous contacte via l'application FasoServices.",
      );
      return resultat;
    } catch (e) {
      _erreur = 'Erreur lors de l\'ouverture de WhatsApp: $e';
      notifyListeners();
      return false;
    }
  }

  // Vérifier la disponibilité du prestataire pour une date donnée
  Future<bool> verifierDisponibilite(DateTime date) async {
    if (_prestataire == null) return false;

    try {
      final QuerySnapshot reservationSnapshot = await _firestore
          .collection(Constants.reservationsCollection)
          .where('prestataireId', isEqualTo: _prestataire!.id)
          .where(
            'dateService',
            isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day),
          )
          .where(
            'dateService',
            isLessThan: DateTime(date.year, date.month, date.day + 1),
          )
          .where('statut', whereIn: ['en_attente', 'confirmee'])
          .get();

      // Vérifier si le prestataire a moins de X réservations ce jour-là (par exemple, max 5)
      const int maxReservationsParJour = 5;
      return reservationSnapshot.docs.length < maxReservationsParJour &&
          _prestataire!.estDisponible;
    } catch (e) {
      _erreur = 'Erreur lors de la vérification de disponibilité: $e';
      notifyListeners();
      return false;
    }
  }

  // Pour les prestataires : mettre à jour les informations du profil
  Future<bool> mettreAJourProfil({
    required String id,
    String? description,
    String? adresse,
    List<String>? categories,
    File? photoProfilFichier,
    List<File>? photosPortfolioFichiers,
    double? latitude,
    double? longitude,
    bool? estDisponible,
  }) async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      if (_prestataire == null) {
        _erreur = 'Profil non chargé';
        return false;
      }

      Map<String, dynamic> donneesMaj = {};

      if (description != null) donneesMaj['description'] = description;
      if (adresse != null) donneesMaj['adresse'] = adresse;
      if (categories != null) donneesMaj['categories'] = categories;
      if (latitude != null) donneesMaj['latitude'] = latitude;
      if (longitude != null) donneesMaj['longitude'] = longitude;
      if (estDisponible != null) donneesMaj['estDisponible'] = estDisponible;

      // Télécharger la photo de profil si elle est modifiée
      if (photoProfilFichier != null) {
        final String cheminStockage =
            'profils/$id/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String? urlPhoto = await _stockageService.telechargerFichier(
          photoProfilFichier,
          cheminStockage,
        );

        if (urlPhoto != null) {
          donneesMaj['photoProfil'] = urlPhoto;
        }
      }

      // Télécharger les photos de portfolio si elles sont modifiées
      if (photosPortfolioFichiers != null &&
          photosPortfolioFichiers.isNotEmpty) {
        List<String> urls = [];

        for (var i = 0; i < photosPortfolioFichiers.length; i++) {
          final String cheminStockage =
              'portfolios/$id/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final String? urlPhoto = await _stockageService.telechargerFichier(
            photosPortfolioFichiers[i],
            cheminStockage,
          );

          if (urlPhoto != null) {
            urls.add(urlPhoto);
          }
        }

        if (urls.isNotEmpty) {
          // Fusionner avec les photos existantes ou remplacer complètement
          donneesMaj['photosPortfolio'] = [
            ..._prestataire!.photosPortfolio,
            ...urls,
          ];
        }
      }

      if (donneesMaj.isEmpty) return true; // Rien à mettre à jour

      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(id)
          .update(donneesMaj);

      // Rafraîchir les données du prestataire
      await chargerPrestataire(id);
      return true;
    } catch (e) {
      _erreur = 'Erreur lors de la mise à jour du profil: $e';
      if (kDebugMode) {
        print(_erreur);
      }
      return false;
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Pour les prestataires : ajouter un nouveau service
  Future<bool> ajouterService({
    required String titre,
    required String description,
    required double prix,
    required String categorie,
    required List<File> photosFichiers,
  }) async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      if (_prestataire == null) {
        _erreur = 'Profil non chargé';
        return false;
      }

      if (kDebugMode) {
        print('Ajout service pour prestataire: ${_prestataire!.id}');
      }

      // Télécharger les photos du service
      List<String> urls = [];
      for (var i = 0; i < photosFichiers.length; i++) {
        final String cheminStockage =
            'services/${_prestataire!.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final String? urlPhoto = await _stockageService.telechargerFichier(
          photosFichiers[i],
          cheminStockage,
        );

        if (urlPhoto != null) {
          urls.add(urlPhoto);
        }
      }

      // Créer un nouveau service
      final DateTime maintenant = DateTime.now();
      final service = Service(
        id: '', // Sera remplacé par Firestore
        prestataireId: _prestataire!.id,
        titre: titre,
        description: description,
        prix: prix,
        categorie: categorie,
        photos: urls,
        estDisponible: true,
        dateCreation: maintenant,
        dateModification: maintenant,
      );

      if (kDebugMode) {
        print('Données du service: ${service.toMap()}');
      }

      // ✅ UTILISEZ L'INSTANCE STOCKÉE
      final serviceId = await _baseDonneesService.creerService(service);

      if (serviceId != null) {
        if (kDebugMode) {
          print('✅ Service ajouté avec ID: $serviceId');
        }
        // Rafraîchir la liste des services
        await chargerServices(_prestataire!.id);
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Échec ajout du service');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERREUR ajout service: $e');
      }
      _erreur = 'Erreur lors de l\'ajout du service: $e';
      return false;
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Pour les prestataires : mettre à jour un service existant
  Future<bool> mettreAJourService({
    required String serviceId,
    String? titre,
    String? description,
    double? prix,
    String? categorie,
    List<File>? photosFichiers,
    bool? estDisponible,
  }) async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      if (_prestataire == null) {
        _erreur = 'Profil non chargé';
        return false;
      }

      Map<String, dynamic> donneesMaj = {
        'dateModification': DateTime.now().millisecondsSinceEpoch,
      };

      if (titre != null) donneesMaj['titre'] = titre;
      if (description != null) donneesMaj['description'] = description;
      if (prix != null) donneesMaj['prix'] = prix;
      if (categorie != null) donneesMaj['categorie'] = categorie;
      if (estDisponible != null) donneesMaj['estDisponible'] = estDisponible;

      // Télécharger les nouvelles photos si fournies
      if (photosFichiers != null && photosFichiers.isNotEmpty) {
        List<String> urls = [];

        for (var i = 0; i < photosFichiers.length; i++) {
          final String cheminStockage =
              'services/${_prestataire!.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final String? urlPhoto = await _stockageService.telechargerFichier(
            photosFichiers[i],
            cheminStockage,
          );

          if (urlPhoto != null) {
            urls.add(urlPhoto);
          }
        }

        if (urls.isNotEmpty) {
          // Obtenir les photos actuelles
          final DocumentSnapshot serviceDoc = await _firestore
              .collection(Constants.servicesCollection)
              .doc(serviceId)
              .get();

          if (serviceDoc.exists) {
            final List<String> photosActuelles = List<String>.from(
              (serviceDoc.data() as Map<String, dynamic>)['photos'] ?? [],
            );

            // Fusionner avec les photos existantes
            donneesMaj['photos'] = [...photosActuelles, ...urls];
          } else {
            donneesMaj['photos'] = urls;
          }
        }
      }

      await _firestore
          .collection(Constants.servicesCollection)
          .doc(serviceId)
          .update(donneesMaj);

      // Rafraîchir la liste des services
      await chargerServices(_prestataire!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _erreur = 'Erreur lors de la mise à jour du service: $e';
      if (kDebugMode) {
        print(_erreur);
      }
      return false;
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Supprimer un service
  Future<void> supprimerService(String serviceId) async {
    _estChargement = true;
    notifyListeners();

    try {
      await _firestore
          .collection(Constants.servicesCollection)
          .doc(serviceId)
          .delete();

      if (_prestataire != null) {
        await chargerServices(_prestataire!.id);
      }
    } catch (e) {
      _erreur = 'Erreur lors de la suppression du service: $e';
      if (kDebugMode) print(_erreur);
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Modifier la disponibilité d’un service (ON/OFF switch)
  Future<void> modifierDisponibiliteService(
    String serviceId,
    bool estDisponible,
  ) async {
    try {
      await _firestore
          .collection(Constants.servicesCollection)
          .doc(serviceId)
          .update({'estDisponible': estDisponible});

      if (_prestataire != null) {
        await chargerServices(_prestataire!.id);
      }
    } catch (e) {
      _erreur = 'Erreur modification disponibilité: $e';
      if (kDebugMode) print(_erreur);
    }
  }

  // Pour les prestataires : supprimer une photo du portfolio
  Future<bool> supprimerPhotoPortfolio(String urlPhoto) async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      if (_prestataire == null) {
        _erreur = 'Profil non chargé';
        return false;
      }

      // Créer une nouvelle liste sans la photo à supprimer
      final List<String> nouvellesPhotos = _prestataire!.photosPortfolio
          .where((photo) => photo != urlPhoto)
          .toList();

      await _firestore
          .collection(Constants.prestatairesCollection)
          .doc(_prestataire!.id)
          .update({'photosPortfolio': nouvellesPhotos});

      // Supprimer le fichier du stockage si possible
      await _stockageService.supprimerFichier(urlPhoto);

      // Rafraîchir les données du prestataire
      await chargerPrestataire(_prestataire!.id);
      return true;
    } catch (e) {
      _erreur = 'Erreur lors de la suppression de la photo: $e';
      if (kDebugMode) {
        print(_erreur);
      }
      return false;
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  // Pour les prestataires : supprimer une photo d'un service
  Future<bool> supprimerPhotoService(String serviceId, String urlPhoto) async {
    _estChargement = true;
    _erreur = null;
    notifyListeners();

    try {
      // Obtenir le service actuel
      final DocumentSnapshot serviceDoc = await _firestore
          .collection(Constants.servicesCollection)
          .doc(serviceId)
          .get();

      if (!serviceDoc.exists) {
        _erreur = 'Service non trouvé';
        return false;
      }

      final List<String> photosActuelles = List<String>.from(
        (serviceDoc.data() as Map<String, dynamic>)['photos'] ?? [],
      );

      // Créer une nouvelle liste sans la photo à supprimer
      final List<String> nouvellesPhotos = photosActuelles
          .where((photo) => photo != urlPhoto)
          .toList();

      await _firestore
          .collection(Constants.servicesCollection)
          .doc(serviceId)
          .update({
            'photos': nouvellesPhotos,
            'dateModification': DateTime.now().millisecondsSinceEpoch,
          });

      // Supprimer le fichier du stockage si possible
      await _stockageService.supprimerFichier(urlPhoto);

      // Rafraîchir la liste des services
      if (_prestataire != null) {
        await chargerServices(_prestataire!.id);
      }
      return true;
    } catch (e) {
      _erreur = 'Erreur lors de la suppression de la photo: $e';
      if (kDebugMode) {
        print(_erreur);
      }
      return false;
    } finally {
      _estChargement = false;
      notifyListeners();
    }
  }

  Future<void> chargerMesServices() async {
    if (_prestataire != null) {
      await chargerServices(_prestataire!.id);
    }
  }
}
