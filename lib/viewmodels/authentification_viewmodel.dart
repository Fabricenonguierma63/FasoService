import 'package:flutter/material.dart';
import '../models/utilisateur.dart';
import '../services/authentification_service.dart';

class AuthentificationViewModel extends ChangeNotifier {
  final AuthentificationService _authService;
  Utilisateur? _utilisateur;
  bool _estEnChargement = false;
  String? _erreur;
  DateTime? _derniereTentativeReinitialisation;

  // Constructeur avec écoute du stream utilisateur
  AuthentificationViewModel(this._authService) {
    _authService.utilisateurActuel.listen((utilisateurFirebase) {
      _utilisateur = utilisateurFirebase;
      notifyListeners();
    });
  }

  // Getters
  Utilisateur? get utilisateur => _utilisateur;
  TypeUtilisateur? get typeUtilisateur => _utilisateur?.type;
  bool get estEnChargement => _estEnChargement;
  String? get erreur => _erreur;
  Stream<Utilisateur?> get utilisateurActuel => _authService.utilisateurActuel;

  // Connexion
  Future<bool> connexion(String email, String motDePasse) async {
    _setChargement(true);
    _setErreur(null);

    try {
      _utilisateur = await _authService.connexion(email, motDePasse);
      _setChargement(false);
      return _utilisateur != null;
    } catch (e) {
      _setChargement(false);
      _setErreur(_gererErreur(e));
      return false;
    }
  }

  // Inscription
  Future<bool> inscription({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
    required TypeUtilisateur type,
  }) async {
    _setChargement(true);
    _setErreur(null);

    try {
      _utilisateur = await _authService.inscription(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        motDePasse: motDePasse,
        type: type,
      );
      _setChargement(false);
      return _utilisateur != null;
    } catch (e) {
      _setChargement(false);
      _setErreur(_gererErreur(e));
      return false;
    }
  }

  // Déconnexion
  Future<void> deconnexion() async {
    _setChargement(true);
    _setErreur(null);

    try {
      await _authService.deconnexion();
      _utilisateur = null;
      _setChargement(false);
    } catch (e) {
      _setChargement(false);
      _setErreur(_gererErreur(e));
    }
  }

  // Réinitialisation mot de passe avec protection contre le spam
  Future<bool> reinitialiserMotDePasse(String email) async {
    // Vérifier si une tentative récente a été faite (limite: 1 minute)
    if (_derniereTentativeReinitialisation != null) {
      final difference = DateTime.now().difference(
        _derniereTentativeReinitialisation!,
      );
      if (difference.inMinutes < 1) {
        _setErreur(
          'Veuillez attendre avant de renvoyer un email (${60 - difference.inSeconds}s restantes)',
        );
        return false;
      }
    }

    _setChargement(true);
    _setErreur(null);

    try {
      await _authService.reinitialiserMotDePasse(email);
      _derniereTentativeReinitialisation = DateTime.now();
      _setChargement(false);
      return true;
    } catch (e) {
      _setChargement(false);
      _setErreur(_gererErreur(e));
      return false;
    }
  }

  // Vérifier si l'utilisateur est connecté
  bool get estConnecte => _utilisateur != null;

  // Obtenir le nom complet de l'utilisateur
  String get nomComplet {
    if (_utilisateur == null) return '';
    return '${_utilisateur!.prenom} ${_utilisateur!.nom}';
  }

  // Chargement avec notification
  void _setChargement(bool enChargement) {
    _estEnChargement = enChargement;
    notifyListeners();
  }

  // Erreur avec notification
  void _setErreur(String? erreur) {
    _erreur = erreur;
    notifyListeners();
  }

  // Gestion des erreurs améliorée
  String _gererErreur(dynamic e) {
    String message = "Une erreur est survenue";
    String errorString = e.toString().toLowerCase();

    // Erreurs d'authentification
    if (errorString.contains("user-not-found")) {
      message = "Aucun compte associé à cet email";
    } else if (errorString.contains("wrong-password")) {
      message = "Mot de passe incorrect";
    } else if (errorString.contains("invalid-credential")) {
      message = "Email ou mot de passe incorrect";
    } else if (errorString.contains("user-disabled")) {
      message = "Ce compte a été désactivé";
    }
    // Erreurs d'inscription
    else if (errorString.contains("email-already-in-use")) {
      message = "Un compte existe déjà avec cet email";
    } else if (errorString.contains("weak-password")) {
      message = "Le mot de passe doit contenir au moins 6 caractères";
    } else if (errorString.contains("invalid-email")) {
      message = "Format d'email invalide";
    }
    // Erreurs de réseau et de service
    else if (errorString.contains("network-request-failed")) {
      message = "Problème de connexion internet. Vérifiez votre réseau.";
    } else if (errorString.contains("too-many-requests")) {
      message = "Trop de tentatives. Veuillez patienter avant de réessayer.";
    } else if (errorString.contains("operation-not-allowed")) {
      message = "Cette opération n'est pas autorisée";
    }
    // Erreurs spécifiques à la réinitialisation de mot de passe
    else if (errorString.contains("invalid-action-code")) {
      message = "Le lien de réinitialisation est invalide ou a expiré";
    } else if (errorString.contains("expired-action-code")) {
      message = "Le lien de réinitialisation a expiré";
    }
    // Erreur générique si aucune correspondance
    else if (errorString.isNotEmpty) {
      message = "Erreur: ${e.toString()}";
    }

    return message;
  }

  // Effacer les erreurs
  void effacerErreur() {
    _erreur = null;
    notifyListeners();
  }

  // Méthode pour vider le cache (logout complet)
  void viderCache() {
    _utilisateur = null;
    _erreur = null;
    _estEnChargement = false;
    _derniereTentativeReinitialisation = null;
    notifyListeners();
  }

  // Debug: obtenir l'état actuel
  Map<String, dynamic> get etatDebug => {
    'utilisateur': _utilisateur?.toString(),
    'estEnChargement': _estEnChargement,
    'erreur': _erreur,
    'derniereTentativeReinitialisation': _derniereTentativeReinitialisation
        ?.toIso8601String(),
  };

  @override
  void dispose() {
    // Nettoyer les ressources si nécessaire
    super.dispose();
  }
}
