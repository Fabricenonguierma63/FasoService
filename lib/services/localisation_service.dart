import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocalisationService {
  // Vérifier si les services de localisation sont activés
  Future<bool> verifierServicesLocalisation() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Demander l'autorisation de localisation
  Future<LocationPermission> demanderAutorisation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  // Obtenir la position actuelle (Android uniquement)
  Future<Position?> obtenirPositionActuelle() async {
    try {
      if (!await verifierServicesLocalisation()) {
        if (!await Geolocator.openLocationSettings()) return null;
      }

      LocationPermission permission = await demanderAutorisation();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      AndroidSettings androidSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 10),
      );

      return await Geolocator.getCurrentPosition(
        locationSettings: androidSettings,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'obtention de la position: $e");
      }
      return null;
    }
  }

  // Convertir une position en adresse
  Future<String?> obtenirAdresseDepuisPosition(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'obtention de l'adresse: $e");
      }
      return null;
    }
  }

  // Convertir une adresse en position
  Future<Position?> obtenirPositionDepuisAdresse(String adresse) async {
    try {
      List<Location> locations = await locationFromAddress(adresse);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'obtention de la position depuis l'adresse: $e");
      }
      return null;
    }
  }

  // Calculer la distance entre deux positions (en kilomètres)
  double calculerDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000;
  }
}
