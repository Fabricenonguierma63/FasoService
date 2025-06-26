enum StatutReservation { enAttente, confirmee, annulee, terminee }

class Reservation {
  final String id;
  final String clientId;
  final String prestataireId;
  final String serviceId;
  final DateTime dateReservation;
  final DateTime dateService;
  final StatutReservation statut;
  final double montant;
  final String? commentaire;
  final bool paiementEffectue;
  final DateTime dateCreation;

  Reservation({
    required this.id,
    required this.clientId,
    required this.prestataireId,
    required this.serviceId,
    required this.dateReservation,
    required this.dateService,
    this.statut = StatutReservation.enAttente,
    required this.montant,
    this.commentaire,
    this.paiementEffectue = false,
    required this.dateCreation,
  });

  Reservation copyWith({
    String? id,
    String? clientId,
    String? prestataireId,
    String? serviceId,
    DateTime? dateReservation,
    DateTime? dateService,
    StatutReservation? statut,
    double? montant,
    String? commentaire,
    bool? paiementEffectue,
    DateTime? dateCreation,
  }) {
    return Reservation(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      prestataireId: prestataireId ?? this.prestataireId,
      serviceId: serviceId ?? this.serviceId,
      dateReservation: dateReservation ?? this.dateReservation,
      dateService: dateService ?? this.dateService,
      statut: statut ?? this.statut,
      montant: montant ?? this.montant,
      commentaire: commentaire ?? this.commentaire,
      paiementEffectue: paiementEffectue ?? this.paiementEffectue,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'prestataireId': prestataireId,
      'serviceId': serviceId,
      'dateReservation': dateReservation.millisecondsSinceEpoch,
      'dateService': dateService.millisecondsSinceEpoch,
      'statut': statutToString(statut),
      'montant': montant,
      'commentaire': commentaire,
      'paiementEffectue': paiementEffectue,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      prestataireId: map['prestataireId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      dateReservation: DateTime.fromMillisecondsSinceEpoch(
        map['dateReservation'],
      ),
      dateService: DateTime.fromMillisecondsSinceEpoch(map['dateService']),
      statut: _stringToStatut(map['statut']),
      montant: (map['montant'] ?? 0.0).toDouble(),
      commentaire: map['commentaire'],
      paiementEffectue: map['paiementEffectue'] ?? false,
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation']),
    );
  }

  static String statutToString(StatutReservation statut) {
    switch (statut) {
      case StatutReservation.enAttente:
        return 'en_attente';
      case StatutReservation.confirmee:
        return 'confirmee';
      case StatutReservation.annulee:
        return 'annulee';
      case StatutReservation.terminee:
        return 'terminee';
    }
  }

  static StatutReservation _stringToStatut(String? statut) {
    switch (statut) {
      case 'en_attente':
        return StatutReservation.enAttente;
      case 'confirmee':
        return StatutReservation.confirmee;
      case 'annulee':
        return StatutReservation.annulee;
      case 'terminee':
        return StatutReservation.terminee;
      default:
        return StatutReservation.enAttente;
    }
  }
}
