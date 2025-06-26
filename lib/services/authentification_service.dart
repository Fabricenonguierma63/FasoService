import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/utilisateur.dart' as model;
import '../models/prestataire.dart' as model;

class AuthentificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Flux d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur actuel sous forme de flux transformé
  Stream<model.Utilisateur?> get utilisateurActuel {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore
            .collection('utilisateurs')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = {'id': doc.id, ...doc.data() as Map<String, dynamic>};

          final type = data['type'];
          if (type == 'prestataire') {
            // Récupérer les données du prestataire depuis la collection prestataires
            final prestataireDoc = await _firestore
                .collection('prestataires')
                .doc(user.uid)
                .get();

            if (prestataireDoc.exists) {
              final prestataireData = {
                'id': prestataireDoc.id,
                ...prestataireDoc.data() as Map<String, dynamic>,
              };
              return model.Prestataire.fromMap(prestataireData);
            }
          }
          return model.Utilisateur.fromMap(data);
        }
      } catch (e) {
        if (kDebugMode) {
          print("Erreur lors de la récupération de l'utilisateur: $e");
        }
      }
      return null;
    });
  }

  Future<model.Utilisateur?> recupererUtilisateurActuel() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('utilisateurs')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          return model.Utilisateur.fromMap({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print("Erreur lors de la récupération de l'utilisateur actuel: $e");
        }
      }
    }
    return null;
  }

  Future<model.Utilisateur?> inscription({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
    required model.TypeUtilisateur type,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final user = result.user;
      if (user != null) {
        final nouvelUtilisateur = model.Utilisateur(
          id: user.uid,
          nom: nom,
          prenom: prenom,
          email: email,
          telephone: telephone,
          type: type,
          dateInscription: DateTime.now(),
          estVerifie: false,
        );

        // 🔥 Enregistrement dans 'utilisateurs'
        await _firestore
            .collection('utilisateurs')
            .doc(user.uid)
            .set(nouvelUtilisateur.toMap());

        // Si c'est un prestataire, ajouter aussi dans 'prestataires'
        if (type == model.TypeUtilisateur.prestataire) {
          final maintenant = DateTime.now();

          final Map<String, dynamic> prestataireData = {
            'id': user.uid,
            'nom': nom,
            'prenom': prenom,
            'email': email,
            'telephone': telephone,
            'photoProfil': '',
            'dateInscription': maintenant.millisecondsSinceEpoch,
            'estVerifie': false,
            'description': '',
            'adresse': '',
            'categories': [],
            'photosPortfolio': [],
            'noteMoyenne': 0.0,
            'nombreAvis': 0,
            'estPremium': false,
            'finAbonnementPremium': null,
            'latitude': 0.0,
            'longitude': 0.0,
            'estDisponible': true,
            'pieceIdentite': [],
            'estVerifieProfessionnellement': false,
          };

          await _firestore
              .collection('prestataires')
              .doc(user.uid)
              .set(prestataireData);
        }

        await user.sendEmailVerification();
        return nouvelUtilisateur;
      }
    } catch (e) {
      if (kDebugMode) print("Erreur d'inscription: $e");
      rethrow;
    }
    return null;
  }

  Future<model.Utilisateur?> connexion(String email, String motDePasse) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final user = result.user;
      if (user != null) {
        final doc = await _firestore
            .collection('utilisateurs')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          return model.Utilisateur.fromMap({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print("Erreur de connexion: $e");
      rethrow;
    }
    return null;
  }

  Future<void> deconnexion() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) print("Erreur de déconnexion: $e");
      rethrow;
    }
  }

  Future<void> reinitialiserMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) print("Erreur de réinitialisation du mot de passe: $e");
      rethrow;
    }
  }

  Future<void> mettreAJourMotDePasse(String nouveauMotDePasse) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(nouveauMotDePasse);
      } else {
        throw Exception("Utilisateur non connecté");
      }
    } catch (e) {
      if (kDebugMode) print("Erreur de mise à jour du mot de passe: $e");
      rethrow;
    }
  }
}
