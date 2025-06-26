import 'package:faso_services/views/commun/custom_splash_screen.dart';
import 'package:flutter/material.dart';
import '../views/auth/connexion_view.dart';
import '../views/auth/inscription_view.dart';
import '../views/client/accueil_view.dart';
import '../views/client/recherche_view.dart';
import '../views/client/detail_prestataire_view.dart';
import '../views/client/reservation_view.dart';
import '../views/client/mes_reservations_view.dart';
import '../views/client/services_view.dart';
import '../views/client/donner_avis_view.dart';
import '../views/prestataire/tableau_bord_view.dart';
import '../views/prestataire/gestion_services_view.dart';
import '../views/prestataire/disponibilites_view.dart';
import '../views/prestataire/demandes_view.dart';
import '../views/commun/profil_view.dart';
import '../views/commun/parametres_view.dart';

class Routes {
  // Routes existantes
  static const String connexion = '/connexion';
  static const String inscription = '/inscription';
  static const String accueil = '/accueil';
  static const String recherche = '/recherche';
  static const String detailPrestataire = '/detail_prestataire';
  static const String reservation = '/reservation';
  static const String mesReservations = '/mes_reservations';
  static const String services = '/services';
  static const String donnerAvis = '/donner_avis';
  static const String tableauBord = '/tableau_bord';
  static const String gestionServices = '/gestion_services';
  static const String disponibilites = '/disponibilites';
  static const String demandes = '/demandes';
  static const String profil = '/profil';
  static const String parametres = '/parametres';

  //NOUVEAU - Méthode pour obtenir toutes les routes (normales + admin)
  static Map<String, WidgetBuilder> obtenirTout() {
    final routes = <String, WidgetBuilder>{};

    // Routes principales
    routes.addAll(_obtenirRoutesNormales());

    return routes;
  }

  // Routes principales (existantes)
  static Map<String, WidgetBuilder> obtenir() {
    return _obtenirRoutesNormales();
  }

  //Méthode privée pour les routes normales
  static Map<String, WidgetBuilder> _obtenirRoutesNormales() {
    return {
      '/splash': (context) => const CustomSplashScreen(),
      connexion: (context) => const ConnexionView(),
      inscription: (context) => const InscriptionView(),
      accueil: (context) => const AccueilView(),
      recherche: (context) => const RechercheView(),
      detailPrestataire: (context) => const DetailPrestataireView(),
      reservation: (context) => const ReservationView(),
      mesReservations: (context) => const MesReservationsView(),
      services: (context) => const ServicesView(),
      donnerAvis: (context) => const DonnerAvisView(),
      tableauBord: (context) => const TableauBordView(),
      gestionServices: (context) => const GestionServicesView(),
      disponibilites: (context) => const DisponibilitesView(),
      demandes: (context) => const DemandesView(),
      profil: (context) => const ProfilView(),
      parametres: (context) => const ParametresView(),
    };
  }
}
