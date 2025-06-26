import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WhatsappService {
  // Ouvrir WhatsApp avec un message pour un numéro donné
  Future<bool> ouvrirWhatsApp(String numero, String message) async {
    try {
      // Formater le numéro en retirant les caractères non numériques
      String numeroFormate = numero.replaceAll(RegExp(r'\D'), '');

      // Encoder le message
      String messageEncode = Uri.encodeComponent(message);

      // Construire l'URL WhatsApp
      Uri url = Uri.parse('https://wa.me/$numeroFormate?text=$messageEncode');

      // Vérifier si WhatsApp peut être ouvert
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'ouverture de WhatsApp: $e");
      }
      return false;
    }
  }

  // Créer un message type pour réserver un service
  String genererMessageReservation({
    required String nomService,
    required String nomPrestataire,
    required DateTime dateService,
    required String adresse,
    String? detailsSupplementaires,
  }) {
    String message = "Bonjour $nomPrestataire,\n\n";
    message += "Je souhaite réserver votre service \"$nomService\" pour le ";
    message += "${dateService.day}/${dateService.month}/${dateService.year} ";
    message +=
        "à ${dateService.hour}h${dateService.minute.toString().padLeft(2, '0')}.\n\n";

    if (adresse.isNotEmpty) {
      message += "Adresse: $adresse\n\n";
    }

    if (detailsSupplementaires != null && detailsSupplementaires.isNotEmpty) {
      message += "Détails: $detailsSupplementaires\n\n";
    }

    message += "Merci de confirmer votre disponibilité.";

    return message;
  }

  // Afficher un dialogue pour confirmer l'ouverture de WhatsApp
  Future<bool> confirmerOuverture(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contacter via WhatsApp'),
            content: const Text(
              'Voulez-vous contacter ce prestataire via WhatsApp ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Contacter'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
