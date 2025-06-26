class Constants {
  // Générales
  static const String appNom = "FasoServices";
  static const String appVersion = "1.0.0";

  // Firebase
  static const String usersCollection = "utilisateurs";
  static const String prestatairesCollection = "prestataires";
  static const String servicesCollection = "services";
  static const String reservationsCollection = "reservations";
  static const String avisCollection = "avis";

  // Catégories de services
  static const List<String> categories = [
    "Coiffure",
    "Couture",
    "Électricité",
    "Plomberie",
    "Mécanique",
    "Menuiserie",
    "Informatique",
    "Nettoyage",
    "Jardinage",
    "Peinture",
    "Cuisine",
    "Autres",
  ];

  // États des réservations
  static const String enAttente = "en_attente";
  static const String confirmee = "confirmee";
  static const String annulee = "annulee";
  static const String terminee = "terminee";

  // Messages
  static const String erreurConnexion =
      "Erreur de connexion. Veuillez réessayer.";
  static const String erreurInscription =
      "Erreur lors de l'inscription. Veuillez réessayer.";
  static const String erreurChargement =
      "Erreur lors du chargement des données.";
  static const String reservationSucces = "Réservation effectuée avec succès!";

  // Formats de date
  static const String formatDate = "dd/MM/yyyy";
  static const String formatHeure = "HH:mm";
  static const String formatDateHeure = "dd/MM/yyyy à HH:mm";

  // Images par défaut
  // Images par défaut
  static const String imageProfilDefaut = "assets/images/profil_defaut.png";
  static const String imageProfilPrestaireDefaut =
      "assets/images/prestataire_defaut.png";
  static const String imageServiceDefaut = "assets/images/service_defaut.png";

  // Durée de validité du cache
  static const int dureeCacheMinutes = 15;

  // Commission sur les services (%)
  static const double pourcentageCommission = 5.0;

  // Abonnement premium (FCFA)
  static const int prixAbonnementMensuel = 2000;
}
