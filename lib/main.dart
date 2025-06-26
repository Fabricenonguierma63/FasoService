import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'viewmodels/authentification_viewmodel.dart';
import 'viewmodels/accueil_viewmodel.dart';
import 'viewmodels/recherche_viewmodel.dart';
import 'viewmodels/prestataire_viewmodel.dart';
import 'viewmodels/reservation_viewmodel.dart';
import 'viewmodels/profil_viewmodel.dart';
import 'services/authentification_service.dart';
import 'services/base_donnees_service.dart';
import 'services/localisation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    await Future.wait([
      initializeDateFormatting(),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthentificationService>(
            create: (_) => AuthentificationService(),
          ),
          Provider<BaseDonneesService>(create: (_) => BaseDonneesService()),
          Provider<LocalisationService>(create: (_) => LocalisationService()),
          ChangeNotifierProvider<AuthentificationViewModel>(
            create: (context) => AuthentificationViewModel(
              context.read<AuthentificationService>(),
            ),
          ),
          ChangeNotifierProvider<AccueilViewModel>(
            create: (context) => AccueilViewModel(
              context.read<BaseDonneesService>(),
              context.read<LocalisationService>(),
            ),
          ),
          ChangeNotifierProvider<RechercheViewModel>(
            create: (context) => RechercheViewModel(
              context.read<BaseDonneesService>(),
              context.read<LocalisationService>(),
            ),
          ),
          ChangeNotifierProvider<PrestataireViewModel>(
            create: (context) =>
                PrestataireViewModel(context.read<BaseDonneesService>()),
          ),
          ChangeNotifierProvider<ReservationViewModel>(
            create: (context) =>
                ReservationViewModel(context.read<BaseDonneesService>()),
          ),
          ChangeNotifierProvider<ProfilViewModel>(
            create: (context) =>
                ProfilViewModel(context.read<BaseDonneesService>()),
          ),
        ],
        child: const FasoServicesApp(),
      ),
    );
  } catch (e) {
    runApp(ErrorApp(error: e));
  }
}

class ErrorApp extends StatelessWidget {
  final Object error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text(
                'Erreur d\'initialisation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
