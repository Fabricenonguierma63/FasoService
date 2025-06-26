import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class StockageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Télécharge un fichier vers Firebase Storage et retourne son URL publique
  /// [fichier] : Le fichier à uploader
  /// [chemin] : Le chemin de stockage (ex: 'profils/user123.jpg')
  /// Retourne l'URL publique ou null en cas d'échec
  Future<String?> telechargerFichier(File fichier, String chemin) async {
    try {
      final ref = _storage.ref().child(chemin);
      await ref.putFile(fichier);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erreur lors du téléchargement du fichier: $e');
      return null;
    }
  }

  /// Supprime un fichier de Firebase Storage via son URL
  /// [url] : L'URL publique du fichier à supprimer
  Future<void> supprimerFichier(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Erreur lors de la suppression du fichier: $e');
      // Ne pas propager l'erreur pour éviter de bloquer l'UI
    }
  }

  /// Télécharge plusieurs fichiers et retourne leurs URLs
  /// [fichiers] : Liste des fichiers à uploader
  /// [dossier] : Dossier de destination dans le stockage
  /// [prefixe] : Préfixe pour le nom des fichiers
  Future<List<String>> telechargerFichiersMultiples({
    required List<File> fichiers,
    required String dossier,
    String prefixe = 'file',
  }) async {
    final List<String> urls = [];

    try {
      for (int i = 0; i < fichiers.length; i++) {
        final chemin =
            '$dossier/$prefixe${DateTime.now().millisecondsSinceEpoch}_$i';
        final url = await telechargerFichier(fichiers[i], chemin);
        if (url != null) {
          urls.add(url);
        }
      }
      return urls;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement multiple: $e');
      return urls; // Retourne les URLs déjà uploadées
    }
  }

  // Méthodes dépréciées (à supprimer dans les futures versions)
  @Deprecated('Utiliser telechargerFichier à la place')
  Future<String> telechargerImage(
    File image,
    String dossier,
    String nom,
  ) async {
    final url = await telechargerFichier(image, '$dossier/$nom');
    return url ?? (throw Exception('Échec du téléchargement'));
  }

  @Deprecated('Utiliser supprimerFichier à la place')
  Future<void> supprimerImage(String url) => supprimerFichier(url);

  @Deprecated('Utiliser telechargerFichiersMultiples à la place')
  Future<List<String>> telechargerImages(
    List<File> images,
    String dossier,
    String prefixe,
  ) => telechargerFichiersMultiples(
    fichiers: images,
    dossier: dossier,
    prefixe: prefixe,
  );
}
