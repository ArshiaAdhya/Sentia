import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primaryDark = Color(0xFF3B5E43);       // Dark forest green used in buttons and highlights
  static const Color primaryMedium = Color(0xFF5D7B63);     // Sage green
  static const Color primaryLight = Color(0xFFC3D2C4);      // Pale moss green
  static const Color creamBackground = Color(0xFFF7F7F0);   // Neutral warm cream background
  
  // Neutral colors
  static const Color textDark = Color(0xFF263328);          // Dark Charcoal-green text
  static const Color textMedium = Color(0xFF5A685D);        // Muted grey-green text
  static const Color glassWhite = Color(0xD9FFFFFF);        // White with 85% opacity
  static const Color glassWhiteHeavy = Color(0xF2FFFFFF);   // White with 95% opacity
  static const Color glassWhiteMuted = Color(0x99FFFFFF);   // White with 60% opacity

  // Accents
  static const Color streakOrange = Color(0xFFFF7E36);      // Warm fiery orange for streak
  static const Color pointBlue = Color(0xFF4BAAF5);         // Cool bright blue for diamonds
  static const Color seedsGreen = Color(0xFF67B04D);        // Rich leaf green for seeds
}

class AppStyles {
  static const String fontFamily = 'Outfit'; // Premium Google Font

  static final TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static final TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static final TextStyle bodyDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  static final TextStyle bodyMuted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textMedium,
  );

  static final TextStyle badgeText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static final BoxDecoration glassCardDeco = BoxDecoration(
    color: AppColors.glassWhite,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static final BoxDecoration glassPillDeco = BoxDecoration(
    color: AppColors.glassWhite,
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
