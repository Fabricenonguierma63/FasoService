import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'utilisateur.dart';
import 'service.dart';

class Prestataire extends Utilisateur {
  final String description;
  final String adresse;
  final List<String> categories;
  final List<String> photosPortfolio;
  final double noteMoyenne;
  final int nombreAvis;
  final bool estPremium;
  final DateTime? finAbonnementPremium;
  final double? latitude;
  final double? longitude;
  final bool estDisponible;
  final List<String> pieceIdentite;
  final bool estVerifieProfessionnellement;
  final List<Service>? mesServices;

  Prestataire({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.telephone,
    super.photoProfil,
    required super.dateInscription,
    super.estVerifie,
    required this.description,
    required this.adresse,
    required this.categories,
    required this.photosPortfolio,
    this.noteMoyenne = 0.0,
    this.nombreAvis = 0,
    this.estPremium = false,
    this.finAbonnementPremium,
    this.latitude,
    this.longitude,
    this.estDisponible = true,
    required this.pieceIdentite,
    this.estVerifieProfessionnellement = false,
    this.mesServices, // ✅ nouvel attribut
  }) : super(type: TypeUtilisateur.prestataire);

  Prestataire copierAvec({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? photoProfil,
    DateTime? dateInscription,
    bool? estVerifie,
    String? description,
    String? adresse,
    List<String>? categories,
    List<String>? photosPortfolio,
    double? noteMoyenne,
    int? nombreAvis,
    bool? estPremium,
    DateTime? finAbonnementPremium,
    double? latitude,
    double? longitude,
    bool? estDisponible,
    List<String>? pieceIdentite,
    bool? estVerifieProfessionnellement,
    List<Service>? mesServices,
  }) {
    return Prestataire(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      photoProfil: photoProfil ?? this.photoProfil,
      dateInscription: dateInscription ?? this.dateInscription,
      estVerifie: estVerifie ?? this.estVerifie,
      description: description ?? this.description,
      adresse: adresse ?? this.adresse,
      categories: categories ?? this.categories,
      photosPortfolio: photosPortfolio ?? this.photosPortfolio,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      nombreAvis: nombreAvis ?? this.nombreAvis,
      estPremium: estPremium ?? this.estPremium,
      finAbonnementPremium: finAbonnementPremium ?? this.finAbonnementPremium,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estDisponible: estDisponible ?? this.estDisponible,
      pieceIdentite: pieceIdentite ?? this.pieceIdentite,
      estVerifieProfessionnellement:
          estVerifieProfessionnellement ?? this.estVerifieProfessionnellement,
      mesServices: mesServices ?? this.mesServices,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'description': description,
      'adresse': adresse,
      'categories': categories,
      'photosPortfolio': photosPortfolio,
      'noteMoyenne': noteMoyenne,
      'nombreAvis': nombreAvis,
      'estPremium': estPremium,
      'finAbonnementPremium': finAbonnementPremium?.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'estDisponible': estDisponible,
      'pieceIdentite': pieceIdentite,
      'estVerifieProfessionnellement': estVerifieProfessionnellement,
    });
    return map;
  }

  factory Prestataire.fromMap(Map<String, dynamic> map) {
    return Prestataire(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'] ?? '',
      photoProfil: map['photoProfil'],
      dateInscription: DateTime.fromMillisecondsSinceEpoch(
        map['dateInscription'],
      ),
      estVerifie: map['estVerifie'] ?? false,
      description: map['description'] ?? '',
      adresse: map['adresse'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      photosPortfolio: List<String>.from(map['photosPortfolio'] ?? []),
      noteMoyenne: (map['noteMoyenne'] ?? 0.0).toDouble(),
      nombreAvis: map['nombreAvis'] ?? 0,
      estPremium: map['estPremium'] ?? false,
      finAbonnementPremium: map['finAbonnementPremium'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['finAbonnementPremium'])
          : null,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      estDisponible: map['estDisponible'] ?? true,
      pieceIdentite: List<String>.from(map['pieceIdentite'] ?? []),
      estVerifieProfessionnellement:
          map['estVerifieProfessionnellement'] ?? false,
    );
  }

  // Calculer la distance entre le prestataire et les coordonnées données (en km)
  double calculerDistance(double lat, double lng) {
    const int rayonTerre = 6371; // Rayon moyen de la Terre en km
    double dLat = _degresVersRadians(lat - latitude!);
    double dLng = _degresVersRadians(lng - longitude!);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degresVersRadians(latitude!)) *
            cos(_degresVersRadians(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = rayonTerre * c;

    return distance;
  }

  // Convertir degrés en radians
  double _degresVersRadians(double degres) {
    return degres * (pi / 180);
  }
}
