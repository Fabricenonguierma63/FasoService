import 'package:faso_services/l10n/app_localizations.dart';
import 'package:faso_services/models/utilisateur.dart';
import 'package:faso_services/views/prestataire/tableau_bord_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../configs/routes.dart';
import '../configs/themes.dart';
import '../viewmodels/authentification_viewmodel.dart';
import '../views/auth/connexion_view.dart';
import '../views/client/accueil_view.dart';

class FasoServicesApp extends StatelessWidget {
  const FasoServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FasoServices',
      theme: ThemeApp.themeActuel,
      debugShowCheckedModeBanner: false,
      routes: Routes.obtenir(),

      // ✅ Localisation
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // Anglais
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },

      // Route initiale
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => Consumer<AuthentificationViewModel>(
              builder: (context, authViewModel, _) {
                return StreamBuilder(
                  stream: authViewModel.utilisateurActuel,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      final utilisateur = snapshot.data;
                      if (utilisateur != null) {
                        final type = utilisateur.type;
                        if (type == TypeUtilisateur.prestataire) {
                          return const TableauBordView();
                        } else {
                          return const AccueilView();
                        }
                      }
                      return const ConnexionView();
                    }
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          color: Couleurs.primaire,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }

        return null;
      },
    );
  }
}
