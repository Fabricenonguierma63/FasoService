import 'package:flutter/material.dart';

class Couleurs {
  static const Color primaire = Color(0xFFFF8C00); // Orange
  static const Color secondaire = Color(0xFF004D40); // Vert foncé
  static const Color fond = Color(0xFFF5F5DC); // Beige clair
  static const Color texte = Color(0xFF212121); // Presque noir
  static const Color texteSecondaire = Color(0xFF757575); // Gris
  static const Color accent = Color(0xFFFFA500); // Orange-jaune
  static const Color blanc = Color(0xFFFFFFFF); // Blanc
  static const Color erreur = Color(0xFFB71C1C); // Rouge foncé
  static const Color succes = Color(0xFF2E7D32); // Vert
}

class ThemeApp {
  static final ThemeData themeActuel = ThemeData(
    primaryColor: Couleurs.primaire,
    scaffoldBackgroundColor: Couleurs.fond,
    colorScheme: ColorScheme.light(
      primary: Couleurs.primaire,
      secondary: Couleurs.secondaire,
      surface: Couleurs.fond,
      error: Couleurs.erreur,
      onPrimary: Couleurs.blanc,
      onSecondary: Couleurs.blanc,
      onSurface: Couleurs.texte,
      onError: Couleurs.blanc,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Couleurs.primaire,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Couleurs.blanc,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Couleurs.texte,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Couleurs.texte,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        color: Couleurs.texte,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Couleurs.texte,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Couleurs.texte,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Poppins',
        color: Couleurs.texteSecondaire,
        fontSize: 12,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Couleurs.blanc,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Couleurs.primaire, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Couleurs.erreur, width: 2),
      ),
      hintStyle: const TextStyle(color: Couleurs.texteSecondaire, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Couleurs.primaire,
        foregroundColor: Couleurs.blanc,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Couleurs.primaire,
        side: const BorderSide(color: Couleurs.primaire, width: 2),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Couleurs.secondaire,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    cardTheme: CardThemeData(
      color: Couleurs.blanc,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Couleurs.blanc,
      selectedItemColor: Couleurs.primaire,
      unselectedItemColor: Couleurs.texteSecondaire,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Couleurs.secondaire,
      foregroundColor: Couleurs.blanc,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Couleurs.secondaire,
      contentTextStyle: const TextStyle(
        color: Couleurs.blanc,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
