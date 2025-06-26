// lib/models/time_slot.dart
import 'package:flutter/material.dart';

// Modèle pour les créneaux horaires
class TimeSlot {
  TimeOfDay debut;
  TimeOfDay fin;

  TimeSlot({required this.debut, required this.fin});

  // Conversion en map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'debut': '${debut.hour}:${debut.minute}',
      'fin': '${fin.hour}:${fin.minute}',
    };
  }

  // Construction à partir d'une map Firestore
  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    final List<String> debutParts = map['debut'].split(':');
    final List<String> finParts = map['fin'].split(':');

    return TimeSlot(
      debut: TimeOfDay(
        hour: int.parse(debutParts[0]),
        minute: int.parse(debutParts[1]),
      ),
      fin: TimeOfDay(
        hour: int.parse(finParts[0]),
        minute: int.parse(finParts[1]),
      ),
    );
  }
}
