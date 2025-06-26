import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/authentification_viewmodel.dart';
import '../../../models/utilisateur.dart';
import '../client/accueil_view.dart';
import '../prestataire/tableau_bord_view.dart';
import '../auth/connexion_view.dart';
import '../../../configs/themes.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 4), () {
      final authViewModel = Provider.of<AuthentificationViewModel>(
        context,
        listen: false,
      );
      final stream = authViewModel.utilisateurActuel;

      stream.first.then((utilisateur) {
        if (!mounted) return;

        if (utilisateur != null) {
          if (utilisateur.type == TypeUtilisateur.prestataire) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TableauBordView()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AccueilView()),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ConnexionView()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Couleurs.accent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', // Ton logo
              width: 300,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }
}
