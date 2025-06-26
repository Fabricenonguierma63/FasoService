class Avis {
  final String id;
  final String clientId;
  final String prestataireId;
  final String? serviceId;
  final double note;
  final String commentaire;
  final DateTime dateCreation;
  final List<String>? photos;

  Avis({
    required this.id,
    required this.clientId,
    required this.prestataireId,
    this.serviceId,
    required this.note,
    required this.commentaire,
    required this.dateCreation,
    this.photos,
  });

  Avis copyWith({
    String? id,
    String? clientId,
    String? prestataireId,
    String? serviceId,
    double? note,
    String? commentaire,
    DateTime? dateCreation,
    List<String>? photos,
  }) {
    return Avis(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      prestataireId: prestataireId ?? this.prestataireId,
      serviceId: serviceId ?? this.serviceId,
      note: note ?? this.note,
      commentaire: commentaire ?? this.commentaire,
      dateCreation: dateCreation ?? this.dateCreation,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'prestataireId': prestataireId,
      'serviceId': serviceId,
      'note': note,
      'commentaire': commentaire,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'photos': photos,
    };
  }

  factory Avis.fromMap(Map<String, dynamic> map) {
    return Avis(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      prestataireId: map['prestataireId'] ?? '',
      serviceId: map['serviceId'],
      note: (map['note'] ?? 0.0).toDouble(),
      commentaire: map['commentaire'] ?? '',
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation']),
      photos: map['photos'] != null ? List<String>.from(map['photos']) : null,
    );
  }
}
