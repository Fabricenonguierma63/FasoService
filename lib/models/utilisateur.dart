enum TypeUtilisateur { client, prestataire }

class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String? photoProfil;
  final TypeUtilisateur type;
  final DateTime dateInscription;
  final bool estVerifie;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.photoProfil,
    required this.type,
    required this.dateInscription,
    this.estVerifie = false,
    String? photoUrl,
  });

  String get nomComplet => '$prenom $nom';

  Utilisateur copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? photoProfil,
    TypeUtilisateur? type,
    DateTime? dateInscription,
    bool? estVerifie,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      photoProfil: photoProfil ?? this.photoProfil,
      type: type ?? this.type,
      dateInscription: dateInscription ?? this.dateInscription,
      estVerifie: estVerifie ?? this.estVerifie,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photoProfil': photoProfil,
      'type': type == TypeUtilisateur.client ? 'client' : 'prestataire',
      'dateInscription': dateInscription.millisecondsSinceEpoch,
      'estVerifie': estVerifie,
    };
  }

  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'] ?? '',
      photoProfil: map['photoProfil'],
      type: map['type'] == 'prestataire'
          ? TypeUtilisateur.prestataire
          : TypeUtilisateur.client,
      dateInscription: DateTime.fromMillisecondsSinceEpoch(
        map['dateInscription'],
      ),
      estVerifie: map['estVerifie'] ?? false,
    );
  }
}
