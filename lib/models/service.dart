class Service {
  // Constantes par défaut
  static const List<String> defaultPhotos = [];
  static const bool defaultAvailable = true;

  final String id;
  final String prestataireId;
  final String titre;
  final String description;
  final double prix;
  final String categorie;
  final List<String> photos;
  final bool estDisponible;
  final DateTime dateCreation;
  final DateTime dateModification;

  Service({
    required this.id,
    required this.prestataireId,
    required this.titre,
    required this.description,
    required this.prix,
    required this.categorie,
    this.photos = defaultPhotos,
    this.estDisponible = defaultAvailable,
    required this.dateCreation,
    required this.dateModification,
  });

  // Créer une copie avec certaines valeurs modifiées
  Service copyWith({
    String? id,
    String? prestataireId,
    String? titre,
    String? description,
    double? prix,
    String? categorie,
    List<String>? photos,
    bool? estDisponible,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Service(
      id: id ?? this.id,
      prestataireId: prestataireId ?? this.prestataireId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      categorie: categorie ?? this.categorie,
      photos: photos ?? this.photos,
      estDisponible: estDisponible ?? this.estDisponible,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  // Convertir en Map pour Firestore (création complète)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prestataireId': prestataireId,
      'titre': titre,
      'description': description,
      'prix': prix,
      'categorie': categorie,
      'photos': photos,
      'estDisponible': estDisponible,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'dateModification': dateModification.millisecondsSinceEpoch,
    };
  }

  // Convertir en Map pour les mises à jour partielles
  Map<String, dynamic> toUpdateMap() {
    return {
      'titre': titre,
      'description': description,
      'prix': prix,
      'categorie': categorie,
      'photos': photos,
      'estDisponible': estDisponible,
      'dateModification': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Créer un Service à partir des données Firestore
  factory Service.fromMap(Map<String, dynamic> map) {
    // Validation des champs requis
    assert(map['id'] != null, 'ID du service est requis');
    assert(map['prestataireId'] != null, 'ID du prestataire est requis');
    assert(map['titre'] != null, 'Titre du service est requis');

    return Service(
      id: map['id'] as String,
      prestataireId: map['prestataireId'] as String,
      titre: map['titre'] as String,
      description: map['description'] as String? ?? '',
      prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
      categorie: map['categorie'] as String? ?? '',
      photos: List<String>.from(map['photos'] ?? defaultPhotos),
      estDisponible: map['estDisponible'] as bool? ?? defaultAvailable,
      dateCreation: DateTime.fromMillisecondsSinceEpoch(
        (map['dateCreation'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      dateModification: DateTime.fromMillisecondsSinceEpoch(
        (map['dateModification'] as int?) ??
            (map['dateCreation'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // Méthodes utilitaires
  bool appartientACategorie(String categorie) {
    return this.categorie.toLowerCase() == categorie.toLowerCase();
  }

  bool estDansLaFourchetteDePrix(double min, double max) {
    return prix >= min && prix <= max;
  }

  @override
  String toString() {
    return 'Service(id: $id, titre: $titre, prix: $prix, disponible: $estDisponible)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service &&
        other.id == id &&
        other.prestataireId == prestataireId;
  }

  @override
  int get hashCode => id.hashCode ^ prestataireId.hashCode;
}
